---
name: rabbitmq-debug
description: Use when RabbitMQ queues are growing, consumers are not processing messages, messages are dead-lettered unexpectedly, or the AMQP connection is dropping.
---

# RabbitMQ Debug

## Activation Rule

**Triggers:**
- Queue depth growing (backlog accumulating)
- Messages going to dead-letter queue unexpectedly
- Consumer count drops to 0
- `ShutdownSignalException` or connection drops in logs
- Messages processed multiple times (duplicate processing)
- "RabbitMQ not working", "messages stuck", "consumer not consuming"

> **Override Directive:** Before touching consumer code, always verify the queue/exchange topology is correct and messages are actually reaching the queue.

## Step 0: Check Memory First

Before any diagnostics, grep shared memory for known RabbitMQ patterns:

```bash
grep -i "rabbitmq\|<repo-name>\|<queue-name>" .github/../../../.copilot-shared/shared/memory/tech-discoveries.md
grep -i "<symptom keyword>" .github/../../../.copilot-shared/shared/memory/known-bugs.md
```

If a matching pattern exists: **go directly to the documented fix.** Skip Steps 1-6.

If no match: run the diagnostic steps below, then use `save-learning` skill to append the finding.

## Diagnostic Checklist

```
[ ] 1. Check queue depth, consumer count, and message rates
[ ] 2. Check exchange → binding → queue routing
[ ] 3. Check dead-letter queue for rejected/expired messages
[ ] 4. Check consumer logs for errors
[ ] 5. Verify prefetch count vs. processing rate
[ ] 6. Verify connection/channel health
[ ] 7. Trace to Java consumer code
```

## Step-by-Step Diagnostics

### Step 1: Check queue status

```bash
# Via CLI
rabbitmqctl list_queues name messages consumers message_stats.publish_details.rate message_stats.deliver_details.rate

# Via Management API
curl -u guest:guest "http://localhost:15672/api/queues/%2F/<queue-name>"
```

**Interpret:**
- `messages` growing + `consumers > 0` → consumers are too slow (prefetch, processing time)
- `messages` growing + `consumers = 0` → consumer crashed or never started
- `consumers > 0` + `messages = 0` → healthy

### Step 2: Verify exchange → routing

```bash
# List bindings for an exchange
curl -u guest:guest "http://localhost:15672/api/exchanges/%2F/<exchange>/bindings/source"

# Publish a test message and check if it arrives
rabbitmqctl publish exchange=<exchange> routing_key=<key> payload="test" properties={}
```

**Common mistakes:**
- Routing key mismatch (consumer listens to `items.created`, publisher sends `item.created`)
- Exchange type wrong (direct vs topic — wildcards only work on topic)
- Queue bound to wrong exchange

### Step 3: Check the dead-letter queue

```bash
# List DLQ messages
rabbitmqctl get queue=<dlq-name> count=10 requeue=false encoding=auto
# Or via API
curl -u guest:guest "http://localhost:15672/api/queues/%2F/<dlq-name>/get" \
  -X POST -H 'Content-Type: application/json' \
  -d '{"count": 5, "requeue": false, "encoding": "auto", "ackmode": "ack_requeue_false"}'
```

**Look at headers of dead-lettered messages:**
- `x-death[].reason`: `rejected` (consumer threw exception + nack) | `expired` (TTL) | `maxlen` (queue full)
- `x-death[].count`: how many times it's been rejected

### Step 4: Find consumer errors in logs

```bash
grep -E "ShutdownSignal|basicNack|channel.*closed|Consumer.*error" app.log | tail -50
grep "AmqpRejectAndDontRequeueException\|ListenerExecutionFailedException" app.log | tail -20
```

### Step 5: Prefetch and processing rate

```bash
# Check current prefetch
curl -u guest:guest "http://localhost:15672/api/channels" | jq '.[].prefetch_count'
```

**Rule of thumb:**
- I/O-bound processing → higher prefetch (50–200)
- CPU-bound → prefetch = number of threads
- Default (prefetch=0) = unlimited = consumer memory bomb — always set a limit

```java
// Spring AMQP
factory.setSimpleContainerFactory(factory -> {
    factory.setPrefetchCount(50);
});
```

### Step 6: Connection / channel health

```bash
# List connections
curl -u guest:guest "http://localhost:15672/api/connections"
# List channels
curl -u guest:guest "http://localhost:15672/api/channels"
```

Look for channels with high `unacked` count → consumer received but hasn't acked (processing too slow or hanging).

---

## Common Problems & Fixes

| Symptom | Root Cause | Fix |
|---|---|---|
| Messages in DLQ with `reason: rejected` | Consumer throws exception → nack without requeue | Fix consumer exception handling; add retry with back-off |
| Consumer stuck, messages unacked | Consumer blocks on I/O without timeout | Add timeout, use async processing with Akka |
| Duplicate processing | `autoAck=true` + consumer crashes mid-process | Use `autoAck=false` + manual ack AFTER processing |
| Connection drops every ~60s | Heartbeat timeout — long GC pause or blocked thread | Increase heartbeat interval or fix the blocking operation |
| Queue fills up | Publish rate > consume rate | Scale consumers, increase prefetch, or throttle publisher |
| Wrong exchange type | Publishing with routing key to `fanout` exchange | Routing keys ignored on fanout — switch to `direct` or `topic` |

---

## Retry with Dead-Letter Pattern

```java
// Queue with retry → DLQ topology
@Bean
Queue itemQueue() {
    return QueueBuilder.durable("items.process")
        .withArgument("x-dead-letter-exchange", "items.dlx")
        .withArgument("x-dead-letter-routing-key", "items.dead")
        .withArgument("x-message-ttl", 30000)  // 30s TTL before DLQ
        .build();
}

// Consumer: nack with requeue=false to send to DLQ
@RabbitListener(queues = "items.process")
public void consume(ItemMessage message, Channel channel, @Header(AmqpHeaders.DELIVERY_TAG) long tag) {
    try {
        processItem(message);
        channel.basicAck(tag, false);
    } catch (RecoverableException e) {
        // Requeue for retry
        channel.basicNack(tag, false, true);
    } catch (Exception e) {
        // Send to DLQ — don't requeue
        channel.basicNack(tag, false, false);
    }
}
```

---

## Useful Management API Endpoints

```bash
BASE="http://localhost:15672/api"
CREDS="-u guest:guest"

curl $CREDS "$BASE/overview"                           # cluster overview
curl $CREDS "$BASE/queues"                             # all queues
curl $CREDS "$BASE/queues/%2F/<name>"                  # specific queue
curl $CREDS "$BASE/exchanges"                          # all exchanges
curl $CREDS "$BASE/bindings"                           # all bindings
curl $CREDS "$BASE/connections"                        # connections
curl $CREDS "$BASE/nodes"                              # node health
```
