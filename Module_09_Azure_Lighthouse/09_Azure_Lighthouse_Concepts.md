# Module 09 — Azure Lighthouse concepts

> **Reading order:** Primer → Concepts (this file) → Lab → Exercises.

Enough detail to **prove and explain** the idea. Full two-tenant deploy is optional for the trainer; students follow the portal walk in the Lab.

---

## 1. The problem

An MSP supports Customer A, B, C… each with their own Entra tenant and Azure subscriptions.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":10}}}%%
flowchart TB
  subgraph BAD["Without Lighthouse"]
    G1["Guests in every customer tenant"]
    G2["Shared admin passwords"]
    G3["One mega-tenant for everyone"]
  end
  style BAD fill:#3a1a1a,stroke:#c50f1f,color:#fff
  style G1 fill:#c50f1f,stroke:#8b0000,color:#fff
  style G2 fill:#c50f1f,stroke:#8b0000,color:#fff
  style G3 fill:#c50f1f,stroke:#8b0000,color:#fff
```

Lighthouse packages cross-tenant **Azure RBAC** as an **offer** the customer accepts.

---

## 2. Big picture

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph MT["MANAGING TENANT — Partner"]
    MU["Users / groups stay in partner Entra"]
    MC["Portal: My customers"]
    MU --- MC
  end
  subgraph CT["CUSTOMER TENANT"]
    CE["Customer owners / billing"]
    SUB["Azure subscription"]
    RG["Resource group / resources"]
    CE -.-> SUB --> RG
  end
  MC -->|"Delegated RBAC<br/>(e.g. Reader)"| RG
  style MT fill:#0b3d5c,stroke:#0078D4,color:#fff
  style CT fill:#1a3d1a,stroke:#107C10,color:#fff
  style MC fill:#50e6ff,stroke:#0078D4,color:#000
  style SUB fill:#FFB900,stroke:#C98400,color:#000
```

Say out loud:

1. Partner signs in to the **partner** tenant.  
2. Customer **keeps ownership** (bill, cancel, revoke).  
3. What crosses the boundary is **Azure RBAC on a scope** — not Global Admin of customer Entra.

---

## 3. Ownership vs management

| Who **owns** | Who **manages** via Lighthouse |
|--------------|--------------------------------|
| Pays the bill | Views / operates within granted roles |
| Can cancel the subscription | Only roles listed in the offer |
| Can revoke the delegation | Only on accepted scopes |
| Directory = customer Entra | Directory = partner Entra |

| Question | Answer |
|----------|--------|
| Whose subscription is it after Lighthouse? | **Customer’s** |
| Does the partner become Global Admin of customer Entra? | **No** |
| Can the customer end access? | **Yes** — remove the assignment |

---

## 4. Guest vs Entra role vs Lighthouse

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart LR
  A["B2B Guest<br/>inside customer Entra"]
  B["Entra directory role<br/>identity power"]
  C["Lighthouse<br/>ARM RBAC across tenants"]
  style A fill:#8764b8,stroke:#5c2d91,color:#fff
  style B fill:#ca5010,stroke:#8a3700,color:#fff
  style C fill:#0078D4,stroke:#005A9E,color:#fff
```

| Tool | Best for |
|------|----------|
| Guest | One collaborator |
| Entra role | Admins of **that** directory |
| Lighthouse | MSP scale — many customers, same partner identities |

---

## 5. Offer + assignment (the contract)

**Offer (registration definition)** = who in the partner tenant gets which Azure role.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  O["Offer"]
  O --> T["managedByTenantId"]
  O --> P["authorizations:<br/>principalId + roleDefinitionId"]
  O --> N["name + description"]
  style O fill:#0078D4,stroke:#005A9E,color:#fff
```

Built-in **Reader** role ID (common in demos): `acdd72a7-3385-48ef-bd42-f606fba81ae7`

Prefer authorizing a **security group** so you add/remove engineers without redeploying the offer.

**Assignment** = customer accepts that offer on a **subscription** or **resource group**.

```mermaid
%%{init: {"theme":"base","sequenceDiagram":{"mirrorActors":false}}}%%
sequenceDiagram
  participant Partner
  participant Offer
  participant Customer
  participant Portal as My customers
  Partner->>Offer: Define who + roles
  Customer->>Offer: Accept (assignment on scope)
  Partner->>Portal: Open delegated resources
```

| Safer demo scope | Riskier |
|------------------|---------|
| One demo RG + **Reader** | Whole subscription + **Owner** |

---

## 6. After acceptance — My customers

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart LR
  U["Partner signs in"] --> M["My customers"] --> S["Customer subscription"] --> R["Delegated RG"]
  R --> W["Reader: list OK"]
  R --> X["Create resource: denied"]
  style M fill:#50e6ff,stroke:#0078D4,color:#000
  style W fill:#107C10,stroke:#0B5A0B,color:#fff
  style X fill:#c50f1f,stroke:#8b0000,color:#fff
```

Lifecycle: define offer → customer accepts → partner operates → customer **revokes** assignment → access ends; customer resources remain.

---

## 7. Map to this training

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph TODAY["What you already use"]
    T["atttraining + Pay-As-You-Go"]
    ADX["ADX adxtrainaug26"]
    APP["Entra app → ingest"]
    T --> ADX
    APP --> ADX
  end
  subgraph STORY["Lighthouse story"]
    MSP["Partner tenant"]
    LH["Delegated Reader on a scope"]
    MSP --> LH -.->|"operate without joining atttraining"| T
  end
  style TODAY fill:#1a3d1a,stroke:#107C10,color:#fff
  style STORY fill:#0b3d5c,stroke:#0078D4,color:#fff
```

| Course piece | Lighthouse? |
|--------------|-------------|
| Log ingest (S3 / Logstash / GuardDuty) | **No** — data plane |
| Entra app secret for kusto plugin | **No** — app auth |
| Partner ops across customer Azure | **Yes** |

---

## Checkpoint questions

1. Who owns the subscription after delegation?  
2. Is Lighthouse the same as inviting a guest?  
3. Why use an **offer** + **assignment** instead of one-off portal clicks?  
4. Why prefer **Reader** on one RG for a first demo?

**One-line summary:** *Partner stays home; customer keeps ownership; Azure RBAC crosses the tenant boundary by delegation.*
