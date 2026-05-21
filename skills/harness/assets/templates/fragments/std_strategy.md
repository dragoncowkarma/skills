## 1. Test Strategy

### 1.1 Testing Levels

| Level | Scope | Tool | Coverage Target | Execution |
|---|---|---|---|---|
| **Unit** | Individual functions/methods | {Jest / pytest / go test} | ≥ 80% line (harness enforced) | Every commit |
| **Integration** | Module interactions | {Supertest / httpx / testing.T} | Key paths covered | Every PR |
| **E2E** | Full user workflows | {Playwright / Cypress} | Critical paths | Pre-release |
| **Performance** | Load & stress | {k6 / locust / ab} | NFR targets met | Sprint review |

### 1.2 TDD Protocol Alignment

This document aligns with the Harness TDD protocol:

| Phase | STD Responsibility | Harness Command |
|---|---|---|
| **RED** | Write test cases (Section 3) → tests MUST FAIL | `harness.sh test --mode tdd-red --id {task_id}-RED --cmd "{cmd}"` |
| **GREEN** | Implementation satisfies tests → tests MUST PASS | `harness.sh test --id {task_id}-GREEN --cmd "{cmd}"` |

### 1.3 Test Naming Convention

```
{module}_{method}_{scenario}_{expectedResult}

Examples:
  auth_login_validCredentials_returnsToken
  auth_login_invalidPassword_returns401
  auth_login_expiredAccount_throwsAccountDisabledError
```

---

## 2. Test Environment

### 2.1 Environment Setup

| Component | Test Configuration | Notes |
|---|---|---|
| **Runtime** | {Node.js 20.x / Python 3.11} | Same as production |
| **Database** | {SQLite in-memory / Docker PostgreSQL} | Reset between test suites |
| **External APIs** | {Mocked via MSW / VCR / responses} | No live API calls in unit tests |
| **File System** | {tmp directory / memfs} | Isolated per test |
| **Environment Variables** | `.env.test` | Separate from dev/prod config |

### 2.2 Test Infrastructure

| Tool | Purpose | Configuration |
|---|---|---|
| `{coverage_tool}` | LCOV coverage generation | `c8 --reporter=lcov` → `coverage/lcov.info` |
| `{test_runner}` | Test execution | `{config file location}` |
| `{mock_library}` | External dependency mocking | — |

### 2.3 Setup & Teardown Procedures

```
beforeAll:
  1. {Initialize test database / Start Docker containers}
  2. {Load seed data}
  3. {Configure mock servers}

afterEach:
  1. {Reset database state}
  2. {Clear mock call history}

afterAll:
  1. {Teardown test database}
  2. {Stop mock servers / Docker containers}
```
