# API Specifications
## 1. Database
- Table `pomodoros`: `id`, `user_id`, `duration_minutes`, `completed_at`

## 2. API Endpoints
- `POST /api/pomodoros`: Save a completed session.
- `GET /api/stats?user_id={id}`: Retrieve daily counts.
