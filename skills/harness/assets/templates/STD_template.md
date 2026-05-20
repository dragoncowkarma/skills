# Software Test Design (STD)

> **Document ID**: STD-{PROJECT_ID}-001
> **Version**: 0.1.0 (Draft)
> **Last Updated**: {DATE}
> **Author**: {AUTHOR}
> **Status**: Draft | In Review | Approved
> **SRS Reference**: [SRS-{PROJECT_ID}-001](../specs/SRS.md)

---

## Quick Start

1. Every test case MUST trace to an SRS requirement via ID
2. Follow TDD-RED/GREEN protocol: write STD entries BEFORE implementation
3. Test case IDs follow format: `TC-{MODULE}-{NNN}`
4. Coverage target: ≥ 80% line coverage (harness enforced)
5. RED phase tests MUST produce `AssertionError` (not `SyntaxError`)

---

## Table of Contents

1. [Test Strategy](#1-test-strategy)
2. [Test Environment](#2-test-environment)
3. [Test Case Specification](#3-test-case-specification)
4. [Boundary & Equivalence Analysis](#4-boundary--equivalence-analysis)
5. [Regression Suite](#5-regression-suite)
6. [Mutation Testing](#6-mutation-testing)
7. [Integration Test Scenarios](#7-integration-test-scenarios)
8. [Performance Test Scenarios](#8-performance-test-scenarios)
9. [Test Data Management](#9-test-data-management)
10. [Traceability Matrix](#10-traceability-matrix)
11. [Related Documents](#11-related-documents)

---

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

---

## 3. Test Case Specification

### 3.1 Test Case Template

> Copy this block for each test case:

#### TC-{MODULE}-{NNN}: {Test Case Title}

| Attribute | Value |
|---|---|
| **ID** | TC-{MODULE}-{NNN} |
| **SRS Requirement** | REQ-{MODULE}-{NNN} |
| **Priority** | Critical / High / Medium / Low |
| **Type** | Unit / Integration / E2E / Performance |
| **TDD Phase** | RED (written before implementation) |

**Preconditions**:
- {System state before test execution}
- {Required test data}
- {Mock/stub configuration}

**Test Steps**:

| Step | Action | Input | Expected Result |
|---|---|---|---|
| 1 | {Setup test context} | {Input data} | {Expected state} |
| 2 | {Execute function under test} | `{function(params)}` | {Return value / side effect} |
| 3 | {Assert result} | — | {Specific assertion} |

**Expected Result**: {Detailed description of the expected outcome}

**Edge Cases Covered**:
- {Null/undefined input}
- {Empty collection}
- {Boundary value}
- {Concurrent access}

**Cleanup**: {Post-test cleanup steps if any}

---

### 3.2 Module: {Module Name}

#### TC-{MODULE}-001: {First Test Case}

*(Use template from 3.1)*

#### TC-{MODULE}-002: {Second Test Case}

*(Use template from 3.1)*

---

## 4. Boundary & Equivalence Analysis

### 4.1 Equivalence Classes

| Input | Valid Classes | Invalid Classes |
|---|---|---|
| `{parameter_name}` | {Class 1: 1-100}, {Class 2: "a"-"z"} | {Class 3: negative numbers}, {Class 4: empty string} |

### 4.2 Boundary Values

| Parameter | Min | Min+1 | Nominal | Max-1 | Max | Below Min | Above Max |
|---|---|---|---|---|---|---|---|
| `{param}` | {0} | {1} | {50} | {99} | {100} | {-1} | {101} |

### 4.3 Boundary Test Cases

| TC ID | Parameter | Value | Expected |
|---|---|---|---|
| TC-BND-001 | `{param}` | {0 (min)} | {Accept / Reject} |
| TC-BND-002 | `{param}` | {-1 (below min)} | {Reject with error} |
| TC-BND-003 | `{param}` | {100 (max)} | {Accept} |
| TC-BND-004 | `{param}` | {101 (above max)} | {Reject with error} |

---

## 5. Regression Suite

### 5.1 Regression Suite Definition

| Suite | Trigger | Test Cases Included | Max Duration |
|---|---|---|---|
| **Smoke** | Every commit | {TC-CORE-001, TC-CORE-002, ...} | 30s |
| **Core** | Every PR | {All unit + critical integration tests} | 5 min |
| **Full** | Pre-release / Nightly | {All test cases in this document} | 30 min |

### 5.2 Regression History

| Date | Suite | Pass | Fail | Skip | New Failures | Root Cause |
|---|---|---|---|---|---|---|
| {DATE} | {Core} | {45} | {2} | {1} | {TC-XXX-002} | {Dependency update broke mock} |

---

## 6. Mutation Testing

### 6.1 Mutation Testing Strategy

| Aspect | Configuration |
|---|---|
| **Tool** | {Stryker / mutmut / go-mutesting} |
| **Target Modules** | {List critical modules for mutation testing} |
| **Mutation Score Target** | ≥ {70%} |
| **Mutant Types** | {Arithmetic, Conditional, Return Value, String} |

### 6.2 Mutation Results

| Module | Mutants Generated | Killed | Survived | Score | Action for Survivors |
|---|---|---|---|---|---|
| `{module}` | {100} | {85} | {15} | {85%} | {Add edge case tests for lines X, Y} |

---

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

---

## 9. Test Data Management

### 9.1 Test Data Strategy

| Data Type | Source | Lifecycle | Sensitivity |
|---|---|---|---|
| **Seed data** | `tests/fixtures/` | Created on setup, destroyed on teardown | No PII |
| **Generated data** | {Faker / factory functions} | Per-test | No PII |
| **Snapshot data** | `tests/__snapshots__/` | Versioned with code | No PII |

### 9.2 Test Data Inventory

| Fixture File | Purpose | Entities | Size |
|---|---|---|---|
| `tests/fixtures/{name}.json` | {Describe the fixture} | {Entity types included} | {Rows/items} |

---

## 10. Traceability Matrix

| SRS Requirement | Test Case(s) | Coverage Status | Last Verified |
|---|---|---|---|
| REQ-{MODULE}-001 | TC-{MODULE}-001, TC-{MODULE}-002 | ✅ Covered | {DATE} |
| REQ-{MODULE}-002 | TC-{MODULE}-003 | ✅ Covered | {DATE} |
| REQ-{MODULE}-003 | — | ❌ **Not Covered** | — |

### Coverage Gap Analysis

| Uncovered Requirement | Reason | Planned Test Case | Target Date |
|---|---|---|---|
| REQ-{MODULE}-003 | {Deferred to Sprint N} | TC-{MODULE}-004 | {DATE} |

---

## 11. Related Documents

| Document | Path | Relationship |
|---|---|---|
| Software Requirements Specification | `docs/specs/SRS.md` | Requirements being tested |
| Software Test Report | `docs/testing/STR.md` | Execution results of these test cases |
| Software Design Document | `docs/specs/SDD.md` | Design informing test approach |
| Troubleshooting Log | `docs/troubleshooting/TROUBLESHOOTING.md` | Test failure investigation history |
