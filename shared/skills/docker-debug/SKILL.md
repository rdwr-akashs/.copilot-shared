---
name: docker-debug
description: Use when debugging Docker container issues — build failures, runtime crashes, networking, volume mounts, health checks, and Docker Compose orchestration problems.
---

# Docker Debug

## Activation Rule

**Triggers:**
- "Container won't start / keeps restarting"
- "Docker build fails"
- "Container exits with code 137/255"
- "Can't connect to service in container"
- "Docker Compose networking issue"
- "Health check failing"
- "OOMKilled"

## Quick Triage Checklist

```
[ ] What's the exit code? (docker inspect --format='{{.State.ExitCode}}' <container>)
[ ] Is it a build failure or runtime failure?
[ ] Did it work before? What changed? (Dockerfile edit, base image update, config)
[ ] Are there resource limits? (memory, CPU)
[ ] Is this local dev or CI/production?
```

## Exit Code Reference

| Exit Code | Signal | Meaning | Common Cause |
|-----------|--------|---------|--------------|
| 0 | — | Clean exit | Process finished normally |
| 1 | — | Application error | Unhandled exception, bad config |
| 126 | — | Permission denied | Entrypoint not executable |
| 127 | — | Command not found | Wrong entrypoint/cmd, missing binary |
| 137 | SIGKILL | Killed | OOM (check `docker stats`), health check failure |
| 139 | SIGSEGV | Segfault | Native library crash |
| 143 | SIGTERM | Terminated | Graceful stop (docker stop) |
| 255 | — | Exit status out of range | Entrypoint script error |

## Debugging Commands

### Container Inspection

```bash
# Check container status and exit details
docker inspect <container> | jq '.[0].State'

# Last 100 log lines
docker logs --tail 100 <container>

# Follow logs live
docker logs -f <container>

# Resource usage
docker stats <container> --no-stream

# Check events (restarts, OOM kills)
docker events --filter container=<container> --since 1h
```

### Build Debugging

```bash
# Build with no cache (force clean rebuild)
docker build --no-cache -t <image> .

# Build with progress output
docker build --progress=plain -t <image> .

# Multi-stage: build specific stage
docker build --target <stage-name> -t <image>-debug .

# Check image layers and sizes
docker history <image>
```

### Networking

```bash
# List networks
docker network ls

# Inspect network (see connected containers + IPs)
docker network inspect <network>

# Test connectivity from inside container
docker exec <container> curl -v http://<service>:<port>/health

# DNS resolution inside container
docker exec <container> nslookup <service-name>

# Check published ports
docker port <container>
```

### Exec Into Container

```bash
# Shell into running container
docker exec -it <container> /bin/bash
# If bash not available:
docker exec -it <container> /bin/sh

# Run as root (useful when user is non-root)
docker exec -u 0 -it <container> /bin/bash
```

## Docker Compose Issues

### Common Problems

| Symptom | Check | Fix |
|---------|-------|-----|
| Service can't reach another service | `docker compose ps` — is target running? | Use service name as hostname, not localhost |
| Port conflict | `docker compose ps` — check port mappings | Change host port in compose file |
| Volume not mounting | `docker compose config` — verify paths | Use absolute paths or named volumes |
| Env vars not set | `docker compose exec <svc> env` | Check `.env` file and `environment:` block |
| Build context too large | `.dockerignore` missing | Add `node_modules`, `.git`, `target` to `.dockerignore` |

### Useful Commands

```bash
# Validate compose file
docker compose config

# Rebuild and restart one service
docker compose up -d --build <service>

# View dependency order
docker compose config --services

# Clean restart (remove volumes too)
docker compose down -v && docker compose up -d
```

## Java-Specific Container Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| OOMKilled with plenty of host RAM | JVM ignores container limits (old JDK) | Use JDK 11+ with `-XX:+UseContainerSupport` (default) |
| Slow startup | JVM ergonomics set too few CPUs | Set `-XX:ActiveProcessorCount=N` |
| High memory baseline | Metaspace + heap + thread stacks | Set `-XX:MaxMetaspaceSize=256m` and `-Xss512k` |
| JMX not reachable | RMI port not exposed | Add `-Dcom.sun.management.jmxremote.port=9090 -Dcom.sun.management.jmxremote.rmi.port=9090` |

## Health Check Patterns

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1
```

If health check fails → container marked unhealthy → orchestrator (Swarm/K8s) may kill it → exit 137.

## Inter-Skill References

- Container logs → `log-analysis` skill for pattern matching
- Performance inside container → `perf-investigator` agent
- Container build in CI → `devops` agent
- Java heap inside container → JVM flags in `systematic-debugging`
