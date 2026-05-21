## 6. Secret Management

> **CRITICAL**: No secrets are stored in this document, source code, or version control.

### 6.1 Secret Storage Strategy

| Environment | Strategy | Tool | Access Control |
|---|---|---|---|
| Development | `.env` file (gitignored) | `dotenv` | Developer-local only |
| Staging | Cloud secret manager | {AWS Secrets Manager / GCP Secret Manager / Vault} | IAM role-based |
| Production | Cloud secret manager + rotation | {AWS Secrets Manager / GCP Secret Manager / Vault} | Strict IAM + audit log |

### 6.2 Secret Inventory

| Secret Name | Environment(s) | Rotation Policy | Owner | Last Rotated |
|---|---|---|---|---|
| `DB_PASSWORD` | Staging, Production | Every 90 days | {Ops team} | {DATE} |
| `{SERVICE}_API_KEY` | All | On compromise or annually | {Service owner} | {DATE} |
| `JWT_SECRET` | Staging, Production | Every 30 days | {Auth team} | {DATE} |

### 6.3 `.env.example` Template

```env
# Copy to .env and fill in values — NEVER commit .env to version control
APP_PORT=3000
APP_ENV=development
DB_HOST=localhost
DB_PORT=5432
DB_NAME={project}_dev
DB_USER={project}
DB_PASSWORD=CHANGE_ME
```
