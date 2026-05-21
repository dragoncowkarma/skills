## 4. Dependency Versions & Lock Policy

### 4.1 Runtime Dependencies

| Package | Pinned Version | Min Supported | Update Policy | Notes |
|---|---|---|---|---|
| `{runtime}` | `{20.11.0}` | `{20.x}` | LTS only | Managed via `.tool-versions` / `Dockerfile` |
| `{framework}` | `{^4.18.2}` | `{4.x}` | Minor auto-update | Lock file enforced |

### 4.2 Dev Dependencies

| Package | Pinned Version | Purpose |
|---|---|---|
| `{test_runner}` | `{^29.7.0}` | Unit/integration testing |
| `{coverage_tool}` | `{^8.0.1}` | LCOV coverage for Harness (≥ 80% required) |
| `{linter}` | `{^3.0.0}` | Code style enforcement |

### 4.3 Lock File Policy

- **Lock file**: `{package-lock.json / yarn.lock / poetry.lock / go.sum}`
- **Commit to VCS**: **Yes** (always)
- **CI validation**: `npm ci` / `pip install --require-hashes` (exact reproduction)
- **Update cadence**: Security patches within 48h, minor versions monthly, major versions require ADR

---

## 5. Build Configuration

### 5.1 Build Targets

| Target | Command | Output | Notes |
|---|---|---|---|
| Development | `{npm run dev / make dev}` | Hot-reload server | Source maps enabled |
| Test | `{npm test / make test}` | Test results + LCOV | Harness integration: `c8 node --test` |
| Production | `{npm run build / make build}` | Optimized bundle | Minified, no source maps |
| Docker | `docker build -t {image}:{tag} .` | Container image | Multi-stage build |

### 5.2 Build Environment Variables

| Variable | Purpose | Required At |
|---|---|---|
| `NODE_ENV` | Build optimization level | Build time |
| `BUILD_VERSION` | Semantic version tag | Build time |
| `COMMIT_SHA` | Git commit hash for traceability | Build time |
