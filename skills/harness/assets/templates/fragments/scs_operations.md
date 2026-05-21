## 9. Rollback Procedures

### 9.1 Application Rollback

| Step | Action | Command | Estimated Time |
|---|---|---|---|
| 1 | Identify failing version | Check monitoring dashboard | 1 min |
| 2 | Rollback deployment | `{kubectl rollout undo / deploy --version PREV}` | 2 min |
| 3 | Verify health | Check health endpoint + key metrics | 2 min |
| 4 | Notify stakeholders | Post in {#incidents channel} | 1 min |

### 9.2 Database Rollback

| Scenario | Strategy | Risk Level | RTO |
|---|---|---|---|
| Schema migration failure | Reverse migration script | Medium | 5-15 min |
| Data corruption | Point-in-time restore from backup | High | 15-60 min |

### 9.3 Safe Database Testing Policy

> **MANDATORY**: All migration scripts and database test operations MUST comply with this policy.

#### 9.3.1 Prohibited Destructive Commands

The following SQL commands are **STRICTLY FORBIDDEN** in auto-generated migrations and agent-created scripts:

| Prohibited Command | Reason | Safe Alternative |
|---|---|---|
| `DROP TABLE` | Irreversible data loss | `ALTER TABLE ... RENAME TO ..._deprecated` |
| `DROP DATABASE` | Catastrophic data loss | Never auto-generate |
| `TRUNCATE TABLE` | Bypasses triggers, no rollback | `DELETE FROM ... WHERE {condition}` |
| `DELETE FROM {table}` (no WHERE) | Unguarded mass deletion | Always include `WHERE` clause |
| `DROP COLUMN` | Silent data loss | Add new column, migrate data, deprecate old |

> **Enforcement**: CI pipelines MUST scan migration files for prohibited patterns before execution. Harness agents are FORBIDDEN from generating these commands.

#### 9.3.2 Memory Database Sandbox (Mandatory for Tests)

| Environment | Database | Configuration |
|---|---|---|
| Unit Tests | SQLite `:memory:` or H2 in-memory | `DB_HOST=:memory:` |
| Integration Tests | Isolated container DB (ephemeral) | Docker-based, destroyed after test |
| Staging | Managed DB with test data subset | Seeded via fixtures, never production data |
| Production | **NEVER** used for testing | Read-only access for monitoring only |

**Agent Rule**: When an AI agent generates migration scripts, it MUST:
1. Test the migration against a memory DB sandbox first
2. Include a reverse migration (rollback) script
3. Never emit `DROP`, `TRUNCATE`, or unguarded `DELETE`
4. Log the migration diff in the cycle log before execution

---

## 10. Feature Flags

| Flag Name | Type | Default | Environments Active | Owner | Expiry |
|---|---|---|---|---|---|
| `{FEATURE_NEW_UI}` | boolean | `false` | Staging, Prod (10% rollout) | {Team} | {DATE} |
| `{FEATURE_V2_API}` | boolean | `false` | Dev, Staging | {Team} | {DATE} |

---

## 11. Monitoring & Alerting Configuration

| Metric | Warning Threshold | Critical Threshold | Alert Channel | Runbook |
|---|---|---|---|---|
| Error rate (5xx) | > 1% | > 5% | {PagerDuty / Slack} | {Link} |
| Response time (p95) | > 500ms | > 2000ms | {Slack} | {Link} |
| CPU utilization | > 70% | > 90% | {Auto-scale + Slack} | {Link} |
| Disk usage | > 70% | > 90% | {PagerDuty} | {Link} |
