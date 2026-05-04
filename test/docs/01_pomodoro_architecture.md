# Pomodoro Timer Architecture
## 1. Frontend (UI)
- TimerView: Manages the 25-minute countdown and controls (start/pause/stop).
- DashboardView: Displays visual statistics of completed Pomodoros.

## 2. Backend (API)
- PomodoroController: Handles incoming requests to record Pomodoros.
- StatsController: Aggregates historical Pomodoro data.

## 3. Database Schema
- PomodoroRecord: Table for storing individual Pomodoro sessions.
