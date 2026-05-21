## 7. Integration Test Scenarios

### 7.1 Integration Test Matrix

| Scenario | Components | Protocol | Test Data | Expected |
|---|---|---|---|---|
| {API → DB: Create} | API Gateway, Database | REST → SQL | {Valid entity JSON} | 201 Created + persisted |
| {API → DB: Read} | API Gateway, Database | REST → SQL | {Existing ID} | 200 + entity data |
| {API → External: Call} | API Gateway, External Service | REST → REST | {Valid request} | 200 + transformed data |

---

## 8. Performance Test Scenarios

### 8.1 Load Test Cases

| Scenario | Tool | Users | Ramp-up | Duration | NFR Target | Pass Criteria |
|---|---|---|---|---|---|---|
| {Steady state} | {k6} | {100} | {30s} | {5 min} | NFR-PERF-001 | p95 < 200ms, error rate < 1% |
| {Peak load} | {k6} | {500} | {60s} | {10 min} | NFR-PERF-002 | p95 < 500ms, error rate < 5% |
| {Stress test} | {k6} | {1000} | {120s} | {15 min} | — | System degrades gracefully |
