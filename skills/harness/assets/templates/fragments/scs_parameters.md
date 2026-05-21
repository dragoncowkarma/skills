## 3. Configuration Parameters

### 3.1 Application Configuration

| Key | Type | Default | Dev | Staging | Prod | Description | Validation Rule |
|---|---|---|---|---|---|---|---|
| `APP_NAME` | string | `{project}` | same | same | same | Application identifier | Non-empty |
| `APP_PORT` | int | `3000` | `3000` | `8080` | `8080` | HTTP listen port | 1024-65535 |
| `APP_ENV` | enum | `development` | `development` | `staging` | `production` | Runtime environment | One of: development, staging, production |
| `LOG_LEVEL` | enum | `info` | `debug` | `info` | `warn` | Minimum log severity | One of: debug, info, warn, error |
| `CORS_ORIGINS` | string[] | `["*"]` | `["*"]` | `["https://staging.*"]` | `["https://{DOMAIN}"]` | Allowed CORS origins | Valid URL patterns |

### 3.2 Database Configuration

| Key | Type | Default | Dev | Staging | Prod | Validation Rule |
|---|---|---|---|---|---|---|
| `DB_HOST` | string | `localhost` | `localhost` | `{staging-host}` | `{prod-host}` | Valid hostname |
| `DB_PORT` | int | `5432` | `5432` | `5432` | `5432` | 1-65535 |
| `DB_NAME` | string | `{project}_dev` | `{project}_dev` | `{project}_staging` | `{project}_prod` | Alphanumeric + underscore |
| `DB_USER` | string | `{project}` | `{project}` | → Secret Store | → Secret Store | Non-empty |
| `DB_PASSWORD` | **SECRET** | — | `dev_password` | → Secret Store | → Secret Store | See secret management fragment |
| `DB_POOL_SIZE` | int | `10` | `5` | `10` | `50` | 1-200 |
| `DB_TIMEOUT_MS` | int | `5000` | `10000` | `5000` | `3000` | > 0 |

### 3.3 External Service Configuration

| Key | Type | Default | Description | Validation Rule |
|---|---|---|---|---|
| `{SERVICE}_API_URL` | string | — | Base URL for {service} | Valid HTTPS URL |
| `{SERVICE}_API_KEY` | **SECRET** | — | API key for {service} | See secret management fragment |
| `{SERVICE}_TIMEOUT_MS` | int | `30000` | Request timeout | > 0 |
| `{SERVICE}_RETRY_COUNT` | int | `3` | Max retry attempts | 0-10 |
