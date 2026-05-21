## 5. Non-Functional Requirements

### 5.1 Performance Requirements

| ID | Requirement | Metric | Target | Measurement Method |
|---|---|---|---|---|
| NFR-PERF-001 | {Response time for API calls} | {Latency (ms)} | {< 200ms p95} | {Load testing with k6} |
| NFR-PERF-002 | {Throughput} | {Requests/sec} | {> 1000 RPS} | {Benchmark suite} |

### 5.2 Security Requirements

| ID | Requirement | Standard/Compliance |
|---|---|---|
| NFR-SEC-001 | {All data at rest must be encrypted} | {AES-256 / SOC2} |
| NFR-SEC-002 | {Authentication via OAuth 2.0 / API keys} | {OWASP Top 10} |

### 5.3 Reliability & Availability

| ID | Requirement | Target |
|---|---|---|
| NFR-REL-001 | {System uptime} | {99.9% (8.76h downtime/year)} |
| NFR-REL-002 | {Mean Time to Recovery} | {< 15 minutes} |

### 5.4 Scalability

| ID | Requirement | Current Baseline | Target |
|---|---|---|---|
| NFR-SCALE-001 | {Concurrent users} | {100} | {10,000} |

### 5.5 Maintainability

| ID | Requirement | Target |
|---|---|---|
| NFR-MAINT-001 | {Test coverage (line)} | {>= 80% (Harness enforced)} |
| NFR-MAINT-002 | {Code review turnaround} | {< 24 hours} |

### 5.6 Usability

| ID | Requirement | Target |
|---|---|---|
| NFR-UX-001 | {Time to complete primary task} | {< 3 clicks / < 30 seconds} |
