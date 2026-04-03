# Flare

Project Flare.

## Technical Architecture Notes
* **Scheduler**: For the scope of this hackathon, the background CheckExecutor and SchedulerService use a simple, in-memory `setInterval`/`setTimeout` approach for interval tracking. While this is sufficient for current requirements, a production-grade release should refactor this to use a robust job queue like BullMQ or Redis to prevent interval loss on server restarts.
