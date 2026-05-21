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
