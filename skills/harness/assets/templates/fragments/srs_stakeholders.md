## 2. Stakeholders & User Classes

### 2.1 Stakeholder Registry

| Stakeholder | Role | Interest | Influence | Communication Channel |
|---|---|---|---|---|
| {Name/Team} | {Product Owner / Developer / End User / Ops} | {High / Medium / Low} | {High / Medium / Low} | {Slack / Email / JIRA} |

### 2.2 User Classes & Characteristics

| User Class | Description | Technical Proficiency | Frequency of Use | Priority |
|---|---|---|---|---|
| {Admin} | {System administrator managing configurations} | {High} | {Daily} | {Primary} |
| {End User} | {Consumer-facing user interacting with UI} | {Low-Medium} | {Daily} | {Primary} |
| {Agent (AI)} | {Autonomous agent executing harness tasks} | {N/A (Programmatic)} | {Continuous} | {Secondary} |

### 2.3 Use Case Diagram

```mermaid
graph TD
    subgraph System Boundary
        UC1["Use Case 1: {Description}"]
        UC2["Use Case 2: {Description}"]
        UC3["Use Case 3: {Description}"]
    end

    Actor1["👤 {User Class 1}"] --> UC1
    Actor1 --> UC2
    Actor2["🤖 {User Class 2}"] --> UC3
    UC1 --> UC2
```
