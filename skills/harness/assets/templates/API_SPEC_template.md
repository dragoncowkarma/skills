# API & Interface Specification (OpenAPI 3.0)

> **Document ID**: API-{PROJECT_ID}-001
> **Version**: 0.1.0 (Draft)
> **Last Updated**: {DATE}
> **Author**: {AUTHOR}
> **Status**: Draft | In Review | Approved | Deprecated
> **SDD Reference**: [SDD-{PROJECT_ID}-001](../specs/SDD.md)

---

## Quick Start

1. The OpenAPI specification below is the **machine-readable source of truth** for all public API contracts.
2. Use an OpenAPI viewer (e.g., Swagger UI, Redocly) to render the interactive documentation.
3. Every endpoint must include request/response examples within the spec.
4. Error codes are standardized in `components.schemas.ErrorResponse`.
5. Sub-agent dispatch protocols (harness-specific) are documented in [Section 2](#2-harness-sub-agent-communication-protocol).
6. Version changes require an ADR when breaking.

---

## Master Index & Lazy-Loading Fragments

AI agents should read only the relevant fragment(s) below to reduce context size.

- **[Section 1: OpenAPI 3.0 Specification](fragments/api_spec_openapi.md)**
  - Full YAML OpenAPI declaration including server list, routes (/health, /{resources}), response components, schema properties, validation errors, and security schemes.
- **[Section 2: Harness Sub-Agent Communication Protocol](fragments/api_spec_protocol.md)**
  - Sub-agent task dispatch contract, permission matrix (`QA`, `DEV`, `DOC`), and telemetry data flow.
- **[Section 3: API Design Standards](fragments/api_spec_standards.md)**
  - Endpoint path conventions, query and body casing rules, HTTP method mapping, standard headers, API versioning policy, and rate limits.
