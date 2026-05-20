# API & Interface Specification (OpenAPI 3.0)

> **Document ID**: API-{PROJECT_ID}-001
> **Version**: 0.1.0 (Draft)
> **Last Updated**: {DATE}
> **Author**: {AUTHOR}
> **Status**: Draft | In Review | Approved | Deprecated
> **SDD Reference**: [SDD-{PROJECT_ID}-001](../specs/SDD.md)

---

## Quick Start

1. The OpenAPI specification below is the **machine-readable source of truth** for all public API contracts
2. Use an OpenAPI viewer (e.g., Swagger UI, Redocly) to render the interactive documentation
3. Every endpoint must include request/response examples within the spec
4. Error codes are standardized in `components.schemas.ErrorResponse`
5. Sub-agent dispatch protocols (harness-specific) are documented in [Section 2](#2-harness-sub-agent-communication-protocol)
6. Version changes require an ADR when breaking

---

## Table of Contents

1. [OpenAPI 3.0 Specification](#1-openapi-30-specification)
2. [Harness Sub-Agent Communication Protocol](#2-harness-sub-agent-communication-protocol)
3. [API Design Standards](#3-api-design-standards)
4. [Related Documents](#4-related-documents)

---

## 1. OpenAPI 3.0 Specification

> **Agent Parsing Rule**: The YAML block below is the canonical API spec. Parse it directly for endpoint discovery, schema validation, and code generation.

```yaml
openapi: 3.0.3

info:
  title: "{PROJECT_NAME} API"
  description: "API specification for {PROJECT_NAME}"
  version: "0.1.0"
  contact:
    name: "{AUTHOR}"
  license:
    name: "MIT"

servers:
  - url: "http://localhost:{PORT}/api/v1"
    description: "Development"
  - url: "https://staging.{DOMAIN}/api/v1"
    description: "Staging"
  - url: "https://{DOMAIN}/api/v1"
    description: "Production"

tags:
  - name: "{Resource}"
    description: "Operations on {resource} entities"
  - name: "Health"
    description: "System health and readiness checks"

paths:
  /health:
    get:
      tags: ["Health"]
      summary: "Health check"
      operationId: "getHealth"
      responses:
        "200":
          description: "Service is healthy"
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: "ok"
                  version:
                    type: string
                    example: "0.1.0"
                  uptime:
                    type: number
                    example: 3600

  /{resources}:
    get:
      tags: ["{Resource}"]
      summary: "List all {resources}"
      operationId: "list{Resources}"
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
            minimum: 1
        - name: pageSize
          in: query
          schema:
            type: integer
            default: 20
            minimum: 1
            maximum: 100
        - name: sortBy
          in: query
          schema:
            type: string
            default: "createdAt"
      responses:
        "200":
          description: "Successful response"
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/PaginatedResponse"
        "401":
          $ref: "#/components/responses/Unauthorized"
        "429":
          $ref: "#/components/responses/RateLimited"
      security:
        - bearerAuth: []

    post:
      tags: ["{Resource}"]
      summary: "Create a new {resource}"
      operationId: "create{Resource}"
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/Create{Resource}Request"
            example:
              name: "Example {resource}"
              description: "A sample {resource}"
      responses:
        "201":
          description: "Created successfully"
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
        "400":
          $ref: "#/components/responses/ValidationError"
        "401":
          $ref: "#/components/responses/Unauthorized"
      security:
        - bearerAuth: []

  /{resources}/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema:
          type: string
          format: uuid

    get:
      tags: ["{Resource}"]
      summary: "Get {resource} by ID"
      operationId: "get{Resource}ById"
      responses:
        "200":
          description: "Successful response"
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
        "404":
          $ref: "#/components/responses/NotFound"
      security:
        - bearerAuth: []

    put:
      tags: ["{Resource}"]
      summary: "Update {resource}"
      operationId: "update{Resource}"
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/Update{Resource}Request"
      responses:
        "200":
          description: "Updated successfully"
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
        "400":
          $ref: "#/components/responses/ValidationError"
        "404":
          $ref: "#/components/responses/NotFound"
      security:
        - bearerAuth: []

    delete:
      tags: ["{Resource}"]
      summary: "Delete {resource}"
      operationId: "delete{Resource}"
      responses:
        "204":
          description: "Deleted successfully"
        "404":
          $ref: "#/components/responses/NotFound"
      security:
        - bearerAuth: []

components:
  schemas:
    SuccessResponse:
      type: object
      properties:
        status:
          type: string
          enum: ["success"]
        data:
          type: object
        meta:
          $ref: "#/components/schemas/Meta"

    PaginatedResponse:
      type: object
      properties:
        status:
          type: string
          enum: ["success"]
        data:
          type: array
          items:
            type: object
        meta:
          $ref: "#/components/schemas/Meta"

    Meta:
      type: object
      properties:
        page:
          type: integer
        pageSize:
          type: integer
        totalCount:
          type: integer

    ErrorResponse:
      type: object
      required: [status, error]
      properties:
        status:
          type: string
          enum: ["error"]
        error:
          type: object
          required: [code, message]
          properties:
            code:
              type: string
              description: "Error code from the Error Code Registry"
              enum:
                - VALIDATION_ERROR
                - UNAUTHORIZED
                - FORBIDDEN
                - NOT_FOUND
                - CONFLICT
                - RATE_LIMITED
                - INTERNAL_ERROR
                - SERVICE_UNAVAILABLE
            message:
              type: string
              description: "Human-readable error message"
            details:
              type: array
              items:
                type: object
                properties:
                  field:
                    type: string
                  message:
                    type: string
            traceId:
              type: string
              description: "X-Request-ID for debugging"

    "Create{Resource}Request":
      type: object
      required: [name]
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 255
        description:
          type: string
          maxLength: 1000

    "Update{Resource}Request":
      type: object
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 255
        description:
          type: string
          maxLength: 1000

  responses:
    ValidationError:
      description: "Request payload fails validation"
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorResponse"
          example:
            status: "error"
            error:
              code: "VALIDATION_ERROR"
              message: "name is required"
              details:
                - field: "name"
                  message: "Cannot be empty"

    Unauthorized:
      description: "Missing or invalid auth token"
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorResponse"
          example:
            status: "error"
            error:
              code: "UNAUTHORIZED"
              message: "Invalid or expired token"

    NotFound:
      description: "Requested resource not found"
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorResponse"
          example:
            status: "error"
            error:
              code: "NOT_FOUND"
              message: "Resource not found"

    RateLimited:
      description: "Too many requests"
      headers:
        Retry-After:
          schema:
            type: integer
          description: "Seconds to wait before retrying"
        X-RateLimit-Limit:
          schema:
            type: integer
        X-RateLimit-Remaining:
          schema:
            type: integer
        X-RateLimit-Reset:
          schema:
            type: integer
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorResponse"

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: "JWT token obtained via authentication endpoint"

    apiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
      description: "API key for service-to-service communication"
```

---

## 2. Harness Sub-Agent Communication Protocol

### 2.1 Task Dispatch Contract

The harness dispatches tasks to sub-agents via task JSON files (`docs/tasks/{task_id}.json`):

| Field | Type | Purpose |
|---|---|---|
| `id` | string | Unique task identifier |
| `assigned_sub_agent` | `"QA" / "Dev" / "Doc" / null` | Target sub-agent role |
| `sub_task_status` | `"Pending" / "InProgress" / "Completed" / "Failed"` | Delegation lifecycle |
| `mechanical_dod.command` | string | Verification command to execute |
| `mechanical_dod.expected_exit_code` | int | Expected result |
| `depends_on` | string[] | Task IDs that must complete first |

### 2.2 Sub-Agent Permissions Matrix

| Sub-Agent | Can Modify `src/` | Can Modify `tests/` | Can Modify `docs/` | Can Modify `.harness/` |
|---|---|---|---|---|
| **QA** (RED) | ❌ | ✅ | ❌ | ❌ |
| **Dev** (GREEN) | ✅ | ✅ | ❌ | ❌ |
| **Doc** (DOCUMENT) | ❌ | ❌ | ✅ | ❌ |

### 2.3 Telemetry Communication

| Event | Producer | Consumer | Data |
|---|---|---|---|
| Test Complete | `harness.sh test` | `.harness/telemetry/{task_id}.log` | Exit code, coverage, duration |
| Status Update | `harness.sh test` | `docs/tasks/{task_id}.json` | Status, hash, metrics |
| Doc Sync | `harness.sh document` | `docs/architecture.md`, `docs/quality_metrics.md` | Generated docs |

---

## 3. API Design Standards

### 3.1 Naming Conventions

| Aspect | Convention | Example |
|---|---|---|
| URL paths | lowercase, kebab-case, plural nouns | `/api/v1/user-profiles` |
| Query params | camelCase | `?pageSize=20&sortBy=createdAt` |
| Request/Response body | camelCase | `{ "firstName": "John" }` |

### 3.2 HTTP Methods

| Method | Purpose | Idempotent | Request Body |
|---|---|---|---|
| `GET` | Retrieve resource(s) | Yes | No |
| `POST` | Create resource | No | Yes |
| `PUT` | Full update / replace | Yes | Yes |
| `PATCH` | Partial update | No | Yes |
| `DELETE` | Remove resource | Yes | No |

### 3.3 Common Headers

| Header | Required | Description |
|---|---|---|
| `Content-Type` | Yes | `application/json` |
| `Accept` | Yes | `application/json` |
| `Authorization` | Conditional | `Bearer {token}` |
| `X-Request-ID` | Recommended | Tracing correlation ID (uuid-v4) |
| `X-API-Version` | Optional | API version override |

### 3.4 Versioning Policy

- **Method**: URL path versioning (`/api/v1/`)
- **Deprecation Notice Period**: 3 months / 2 releases
- A change is **breaking** if it removes/renames endpoints, changes field types, or adds required parameters
- Breaking changes require an [ADR](../decisions/ADR-001.md)

### 3.5 Rate Limiting

| Tier | Limit | Window |
|---|---|---|
| Anonymous | 30 req | 1 min |
| Authenticated | 100 req | 1 min |
| Internal | 1000 req | 1 min |

---

## 4. Related Documents

| Document | Path | Relationship |
|---|---|---|
| Software Design Document | `docs/specs/SDD.md` | Architecture defining interfaces |
| Software Requirements Specification | `docs/specs/SRS.md` | Requirements driving API design |
| Software Configuration Specification | `docs/specs/SCS.md` | Environment-specific API config |
| Architecture Decision Records | `docs/decisions/ADR-*.md` | API versioning and design decisions |
