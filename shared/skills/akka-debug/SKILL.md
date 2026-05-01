---
name: akka-debug
description: Use when Akka actors have dead letters, ask timeouts, stuck actors, dispatcher starvation, or blocking operations inside actors. Systematic Akka debugging workflow.
---

# Akka Debug

## Activation Rule

**Triggers:**
- Dead letters flooding the log
- `AskTimeoutException` on actor ask patterns
- Actor appears to stop processing (messages queue up)
- `BlockingStarvedException` or dispatcher thread exhaustion
- Actor restarts looping (supervisor restarts storm)
- "Akka not processing", "dead letter for [message]", "actor timeout"

> **Override Directive:** Enable Akka logging before guessing. Dead letters and mailbox monitoring give you the exact actor path and message — don't diagnose blind.

## Step 0: Check Memory First

Before any diagnostics, grep shared memory for known Akka patterns:

```bash
grep -i "akka\|<repo-name>\|<actor-name>" .github/../../../.copilot-shared/shared/memory/tech-discoveries.md
grep -i "<symptom keyword>" .github/../../../.copilot-shared/shared/memory/known-bugs.md
```

If a matching pattern exists: **go directly to the documented fix.** Skip Steps 1-7.

If no match: run the diagnostic steps below, then use `save-learning` skill to append the finding.

## Diagnostic Checklist

```
[ ] 1. Enable dead-letter logging and find the actor path
[ ] 2. Check if the actor is alive (via actorSelection or monitoring)
[ ] 3. Find the supervisor strategy for the failing actor
[ ] 4. Check for blocking operations inside the actor's receive
[ ] 5. Check dispatcher configuration and thread pool size
[ ] 6. Look for ask() calls without proper timeout
[ ] 7. Check mailbox size (unbounded vs bounded)
```

## Step 1: Enable Akka Diagnostics Logging

In `application.conf` or `reference.conf`:

```hocon
akka {
  log-dead-letters = 20
  log-dead-letters-during-shutdown = on
  actor {
    debug {
      receive = on          # log all received messages
      lifecycle = on        # log actor start/stop/restart
      unhandled = on        # log unhandled messages
    }
  }
  # For mailbox monitoring
  mailbox {
    requirements {
      "akka.dispatch.BoundedMessageQueueSemantics" = "bounded-mailbox"
    }
  }
}
```

## Step 2: Interpret Dead Letter Log

```
[akka://mySystem/user/ItemSupervisor/item-processor-1] Message [com.radware.items.ProcessItemMessage] 
from Actor[akka://mySystem/user/ItemController#1234] to Actor[akka://mySystem/user/ItemSupervisor/item-processor-1#5678] 
was not delivered. [3] dead letters encountered.
```

**Read the dead letter:**
- `to Actor[...#5678]` → the `#` followed by a number means the actor has TERMINATED. The sender has a stale `ActorRef`.
- `from Actor[...]` → who sent the undeliverable message
- `Message [...]` → what message type

**Common causes:**
- Stale `ActorRef` (actor died, ref not updated)
- Sending to `ActorRef.noSender()` or `deadLetters` intentionally
- Race condition: sender created before receiver was ready

## Step 3: Check Supervisor Strategy

Find the supervisor for the dead actor:

```bash
grep -rn "SupervisorStrategy\|OneForOneStrategy\|AllForOneStrategy" src/ --include="*.java"
grep -rn "supervise\|supervisorStrategy" src/ --include="*.java"
```

Common supervisor strategy problems:

```java
// BAD: Escalates all exceptions — kills the supervisor too
@Override
public SupervisorStrategy supervisorStrategy() {
    return new OneForOneStrategy(
        DeciderBuilder.matchAny(e -> SupervisorStrategy.escalate()).build()
    );
}

// BETTER: Restart for recoverable, stop for fatal
@Override
public SupervisorStrategy supervisorStrategy() {
    return new OneForOneStrategy(
        10,
        Duration.ofMinutes(1),
        DeciderBuilder
            .match(IOException.class, e -> SupervisorStrategy.restart())
            .match(IllegalArgumentException.class, e -> SupervisorStrategy.resume())
            .matchAny(e -> SupervisorStrategy.escalate())
            .build()
    );
}
```

## Step 4: Find Blocking in Actors

**Blocking inside an actor's `receive` starves the dispatcher.**

```bash
# Find Thread.sleep, synchronized blocks, and blocking I/O in actor classes
grep -rn "Thread.sleep\|synchronized\|\.get()\|\.join()\|ResultSet\|InputStream" \
  src/main/java/com/radware/actors/ --include="*.java"
```

Blocking patterns to move to a separate dispatcher:

```java
// BAD: Blocking call in actor receive
@Override
public Receive<Command> createReceive() {
    return newReceiveBuilder()
        .onMessage(FetchData.class, msg -> {
            String result = httpClient.get(msg.url()).block();  // BLOCKS dispatcher thread!
            // ...
        })
        .build();
}

// GOOD: Send blocking work to a dedicated blocking dispatcher
CompletableFuture.supplyAsync(
    () -> httpClient.get(msg.url()).block(),
    blockingDispatcher
).thenAccept(result -> self().tell(new DataFetched(result), ActorRef.noSender()));
```

## Step 5: Dispatcher Configuration

```hocon
# In application.conf

# Default dispatcher (non-blocking work)
akka.actor.default-dispatcher {
  type = Dispatcher
  executor = "fork-join-executor"
  fork-join-executor {
    parallelism-min = 4
    parallelism-factor = 2.0  # threads = factor * CPUs
    parallelism-max = 16
  }
}

# Blocking dispatcher (I/O, database, blocking HTTP)
blocking-io-dispatcher {
  type = Dispatcher
  executor = "thread-pool-executor"
  thread-pool-executor {
    fixed-pool-size = 32   # thread per concurrent blocking call
  }
  throughput = 1
}
```

Assign a blocking actor to the blocking dispatcher:

```java
ActorRef blockingActor = system.actorOf(
    Props.create(BlockingActor.class)
         .withDispatcher("blocking-io-dispatcher"),
    "blocking-actor"
);
```

## Step 6: Ask Timeout Debugging

```java
// Find all ask() calls in actor code
grep -rn "Patterns.ask\|AskPattern.ask\|\.ask(" src/ --include="*.java"
```

`AskTimeoutException` means the actor:
1. Never received the message (dead, wrong ref, mailbox full)
2. Received but took too long (blocking, overloaded)
3. Received but replied to the wrong `ActorRef` (forgot to reply)

Check the response path:

```java
// Common mistake: forgetting to reply
case ProcessItem msg -> {
    Item item = processItem(msg.id());
    // BUG: no reply sent! The ask() caller will timeout
    // FIX: getSender().tell(new ItemProcessed(item), getSelf());
}
```

## Step 7: Restart Storm Detection

```bash
# Count actor restarts in log
grep "restarting\|Restarting" app.log | wc -l
grep "restarting\|Restarting" app.log | awk '{print $1}' | cut -c1-16 | sort | uniq -c
```

If restart count is very high in a short window:
- Supervisor restart limit exceeded → actor stopped permanently
- Fix the root cause exception, don't just adjust restart limits

## Common Akka Problems & Fixes

| Symptom | Root Cause | Fix |
|---|---|---|
| Dead letter with `#` in sender | Stale ActorRef after restart | Use `ActorSelection` or re-lookup on `Terminated` |
| AskTimeoutException | Actor too slow or blocking | Move blocking to separate dispatcher |
| Messages queue up | Dispatcher thread pool exhausted | Increase pool size or move blocking work |
| Restart storm | Supervisor escalating too aggressively | Tune restart limit or match specific exception types |
| Unhandled message | Missing case in receive builder | Add `matchAny` for defensive logging |
| Actor never stops | Missing `stop(self())` on poison pill | Implement `PoisonPill` handling explicitly |

## Hard Rules

- **Never do blocking I/O on the default dispatcher.** Always use a dedicated blocking dispatcher.
- **Always handle `Terminated`** when you watch an actor with `context.watch()`.
- **Set ask timeout explicitly** — never rely on a default. Short enough to detect failure, long enough for realistic processing.
- **Log `unhandled` messages** in production — they indicate protocol bugs.
- **Bounded mailboxes in production** — unbounded mailboxes can cause OOM if a slow actor is flooded.
