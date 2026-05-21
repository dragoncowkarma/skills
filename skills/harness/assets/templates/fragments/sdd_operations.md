## 7. Dependency Management

### 7.1 Dependency Tree

| Package | Version | Purpose | License | Risk Level |
|---|---|---|---|---|
| `{package}` | `{^1.2.3}` | {What it does} | {MIT / Apache-2.0} | {Low / Medium / High} |

### 7.2 Dependency Update Policy

- **Security patches**: Apply within {24h / 1 week}
- **Minor versions**: Review and apply in next sprint
- **Major versions**: Requires ADR and migration plan

### 7.3 Vendoring / Lock Strategy

- **Lock file**: {package-lock.json / poetry.lock / go.sum}
- **Vendoring**: {Yes / No} — {Rationale}

---

## 8. Error Handling & Resilience

### 8.1 Error Classification

| Category | Example | Handling Strategy | User-Facing Message |
|---|---|---|---|
| **Validation Error** | Invalid input format | Return 400 + field-level errors | "Please check your input" |
| **Business Logic Error** | Insufficient permissions | Return 403 + reason | "You don't have access" |
| **Infrastructure Error** | Database timeout | Retry (3x with backoff) → fallback | "Service temporarily unavailable" |
| **Fatal Error** | Out of memory | Log + alert + graceful shutdown | "System error. Contact support." |

### 8.2 Retry & Circuit Breaker Policy

| Operation | Max Retries | Backoff Strategy | Circuit Breaker Threshold |
|---|---|---|---|
| `{DB queries}` | 3 | Exponential (100ms, 200ms, 400ms) | 5 failures in 60s |
| `{External API}` | 2 | Linear (500ms) | 3 failures in 30s |

### 8.3 Logging Standards

| Level | When to Use | Includes PII? | Retention |
|---|---|---|---|
| `ERROR` | Unrecoverable failures | No | 90 days |
| `WARN` | Recoverable issues, degraded performance | No | 30 days |
| `INFO` | Key business events, state transitions | No | 14 days |
| `DEBUG` | Detailed diagnostic information | No (redacted) | 7 days |

---

## 9. Security Design

### 9.1 Authentication & Authorization

| Aspect | Design | Notes |
|---|---|---|
| **Authentication** | {JWT / OAuth2 / API Key} | {Token expiry: 1h / Refresh: 7d} |
| **Authorization** | {RBAC / ABAC / ACL} | {Role hierarchy: Admin > Editor > Viewer} |
| **Secret Management** | {Environment variables / Vault / KMS} | Reference [SCS](../specs/SCS.md) |

### 9.2 Data Protection

| Data Type | At Rest | In Transit | Access Control |
|---|---|---|---|
| {User credentials} | {bcrypt / argon2} | {TLS 1.3} | {Auth service only} |
| {PII} | {AES-256-GCM} | {TLS 1.3} | {Scoped access} |

### 9.3 Input Validation

- **Strategy**: {Whitelist / Schema validation / Parameterized queries}
- **Sanitization**: {HTML escaping / SQL parameterization / Path traversal prevention}
