# Software Design Document (SDD)

> **Document ID**: SDD-{PROJECT_ID}-001
> **Version**: 0.1.0 (Draft)
> **Last Updated**: {DATE}
> **Author**: {AUTHOR}
> **Status**: Draft | In Review | Approved | Superseded
> **SRS Reference**: [SRS-{PROJECT_ID}-001](../specs/SRS.md)

---

## Quick Start

1. Ensure the SRS is at least in "In Review" status before writing this document
2. Start with Architecture Overview (Section 2) — draw the big picture first
3. Each component in Component Design (Section 3) MUST map to at least one SRS requirement
4. Use mermaid diagrams for all visual representations
5. Reference ADR for every significant design choice

---

## Master Index & Lazy-Loading Fragments

AI agents should read only the relevant fragment(s) below to reduce context size.

- **[Section 1 & 2: Introduction & Architecture Overview](fragments/sdd_overview.md)**
  - Design philosophy, technology stack, system architecture diagram, patterns, boundaries, module boundary maps.
- **[Section 3: Component Design](fragments/sdd_components.md)**
  - Class structures, state management, concurrency models, public interfaces, and dependency diagrams.
- **[Section 4: Data Design & Safe Migrations](fragments/sdd_data.md)**
  - Entity relationship diagrams (ERD), data dictionaries, data flows, and safe migration policies.
- **[Section 5: Interface Design](fragments/sdd_interfaces.md)**
  - Internal (module-to-module) and external service interfaces.
- **[Section 6: Sequence Diagrams](fragments/sdd_flow.md)**
  - Critical paths, primary user flows, and error recovery sequence diagrams.
- **[Section 7, 8, & 9: Operations, Dependencies, Resilience & Security](fragments/sdd_operations.md)**
  - Dependency trees, error classification, retry policies, logging standards, auth/authz, data protection.

---

## Related Documents

| Document | Path | Relationship |
|---|---|---|
| Software Requirements Specification | `docs/specs/SRS.md` | Requirements this design implements |
| Software Configuration Specification | `docs/specs/SCS.md` | Configuration & environment details |
| Architecture Decision Records | `docs/decisions/ADR-*.md` | Formal decision rationale |
| API Specification | `docs/api/API_SPEC.md` | Detailed interface contracts |
| Semantic Map | `docs/map.md` | Auto-generated symbol index |
