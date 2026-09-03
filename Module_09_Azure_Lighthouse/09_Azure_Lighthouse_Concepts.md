# Module 09 — Azure Lighthouse concepts

> **Reading order:** Primer → Concepts (this file) → Exercises.

This module is **concepts only**. You learn how Azure Lighthouse works with diagrams and plain English. There is no hands-on lab and no second tenant in class.

---

## 1. Start with a story

Imagine a company called **Contoso Consulting**. Contoso helps many clients run Azure.

- Client **A** has its own Entra ID (its own company login world) and its own Azure bill.  
- Client **B** has another Entra ID and another bill.  
- Client **C** the same.

Contoso’s engineers already have accounts in **Contoso’s** Entra ID. Contoso does **not** want to:

1. Create a guest account for every engineer inside **every** client tenant, or  
2. Ask clients for Global Admin passwords, or  
3. Force every client to join Contoso’s one big tenant (clients would lose isolation and clear billing).

Clients want something else:

> “Contoso may **look after** these Azure resources, with **limited** rights. **We** still own the subscription. We can **stop** Contoso anytime.”

That packaged, cross-company grant is what **Azure Lighthouse** is for.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":10}}}%%
flowchart TB
  subgraph BAD["Painful options without Lighthouse"]
    G1["Invite every engineer<br/>as a guest into every client"]
    G2["Share admin passwords"]
    G3["Put all clients in one mega-tenant"]
  end
  style BAD fill:#3a1a1a,stroke:#c50f1f,color:#fff
  style G1 fill:#c50f1f,stroke:#8b0000,color:#fff
  style G2 fill:#c50f1f,stroke:#8b0000,color:#fff
  style G3 fill:#c50f1f,stroke:#8b0000,color:#fff
```

| Bad pattern | Why it hurts |
|-------------|--------------|
| Guests everywhere | Hard to join/leave; client must manage Contoso people |
| Shared passwords | No real audit; security risk |
| One mega-tenant | Clients lose separation, compliance, and clear ownership |

**Simple definition:** Lighthouse lets a **partner tenant** receive **Azure roles** (like Reader) on a **customer subscription or resource group**, without moving the partner’s people into the customer’s Entra ID.

---

## 2. Two tenants, one clear job each

In Lighthouse language:

| Name | Who | Everyday meaning |
|------|-----|------------------|
| **Managing tenant** | Partner / MSP (Contoso) | Where Contoso staff sign in every day |
| **Customer tenant** | Client | Where the client’s users and billing live |
| **Scope** | Subscription or resource group | *Which* Azure resources Contoso may touch |
| **Role** | e.g. Reader, Contributor | *How much* Contoso may do |

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph MT["MANAGING TENANT — Partner"]
    MU["Partner users and groups<br/>stay in partner Entra ID"]
    MC["Azure portal → My customers"]
    MU --- MC
  end
  subgraph CT["CUSTOMER TENANT — Client"]
    CE["Client owners and billing admins"]
    SUB["Azure subscription<br/>(client still owns it)"]
    RG["Resource groups and resources<br/>e.g. ADX, VMs, storage"]
    CE -.->|"owns / pays"| SUB
    SUB --> RG
  end
  MC -->|"Lighthouse delegation<br/>Azure RBAC only<br/>(example: Reader)"| RG
  style MT fill:#0b3d5c,stroke:#0078D4,color:#fff
  style CT fill:#1a3d1a,stroke:#107C10,color:#fff
  style MU fill:#0078D4,stroke:#005A9E,color:#fff
  style MC fill:#50e6ff,stroke:#0078D4,color:#000
  style CE fill:#107C10,stroke:#0B5A0B,color:#fff
  style SUB fill:#FFB900,stroke:#C98400,color:#000
  style RG fill:#fff4ce,stroke:#C98400,color:#000
```

**Three sentences to remember**

1. Contoso staff sign in to **Contoso**, not as permanent guests in every client.  
2. The client still **owns** the subscription (pays, can cancel, can revoke Contoso).  
3. What Contoso receives is **Azure Resource Manager permission** on a chosen scope — **not** “Global Admin of the client’s Entra directory.”

---

## 3. Ownership vs management (do not mix these up)

This is the most important distinction in the module.

**Own** = “This is my subscription.”  
**Manage (via Lighthouse)** = “You allowed me to operate inside rules you set.”

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart LR
  subgraph OWN["Customer OWNS"]
    O1["Pays the Azure bill"]
    O2["Can cancel the subscription"]
    O3["Can revoke the partner"]
    O4["Entra directory = customer"]
  end
  subgraph MGT["Partner MANAGES via Lighthouse"]
    M1["Can view or change resources<br/>only if the role allows it"]
    M2["Only roles listed in the offer"]
    M3["Only on scopes the customer accepted"]
    M4["Entra directory = partner"]
  end
  style OWN fill:#107C10,stroke:#0B5A0B,color:#fff
  style MGT fill:#0078D4,stroke:#005A9E,color:#fff
```

| Question | Simple answer |
|----------|----------------|
| After Lighthouse, whose subscription is it? | Still the **customer’s** |
| Can the partner delete the customer’s Entra tenant? | **No** |
| Can the customer remove the partner tomorrow? | **Yes** — remove the delegation (assignment) |
| Does Lighthouse make Contoso a Global Admin of the client? | **No** — only the Azure roles in the offer |

Analogy: giving a building contractor a **key to one floor** is not the same as putting them on the **property deed**. Lighthouse is the key (with a role and a floor). Ownership stays with the client.

---

## 4. Three tools people confuse — keep them separate

People often say “just add them to our Azure AD” or “give them Owner.” Those are different tools.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph CMP["Three different tools"]
    direction LR
    A["B2B Guest<br/>Person is invited INTO<br/>the customer Entra ID"]
    B["Entra directory role<br/>e.g. Global Admin<br/>Power over the directory"]
    C["Azure Lighthouse<br/>Azure RBAC across<br/>the tenant boundary"]
  end
  A --> A1["Good for one person helping for a while"]
  B --> B1["Good for admins of that one company"]
  C --> C1["Good for an MSP with many customers"]
  style A fill:#8764b8,stroke:#5c2d91,color:#fff
  style B fill:#ca5010,stroke:#8a3700,color:#fff
  style C fill:#0078D4,stroke:#005A9E,color:#fff
```

| Tool | Where the person “lives” | What they get |
|------|--------------------------|---------------|
| **B2B guest** | Appears inside the **customer** tenant as a guest | Whatever roles the customer assigns locally |
| **Entra directory role** | Inside one directory | Power over **users/apps** in that directory (not the same as Azure Owner) |
| **Lighthouse** | Stays in the **partner** tenant | Azure resource roles on a customer scope, by delegation |

**Classroom line for this ADX course**

- Module 05 **Entra app** for Logstash = “an application may **ingest data** into ADX.”  
- Module 09 **Lighthouse** = “a partner company may **operate Azure resources** in another company’s subscription.”  

Same cloud family, **different problems**. Do not mix them.

---

## 5. The contract: offer + assignment

Lighthouse does not use a handshake and hope. It uses two named pieces.

### Offer (also called registration definition)

Think of a **contract card** the partner prepares:

- Which partner tenant is managing?  
- Which partner users or **groups** are allowed?  
- Which Azure role do they get? (for teaching, often **Reader** = view only)

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  OFFER["OFFER = contract card"]
  OFFER --> T["Managing tenant ID<br/>which partner company"]
  OFFER --> P["Who is allowed?<br/>usually a security group"]
  OFFER --> R["Which Azure role?<br/>e.g. Reader"]
  OFFER --> N["Name and description<br/>shown to the customer"]
  style OFFER fill:#0078D4,stroke:#005A9E,color:#fff
  style T fill:#50e6ff,stroke:#0078D4,color:#000
  style P fill:#FFB900,stroke:#C98400,color:#000
  style R fill:#FFB900,stroke:#C98400,color:#000
  style N fill:#e8e8e8,stroke:#666,color:#000
```

**Why a group instead of one user?**  
When Contoso hires or fires an engineer, they add/remove the person from the group in Contoso’s Entra ID. They do not rewrite the whole customer contract for every hire.

### Assignment (acceptance)

An offer alone does nothing useful until the **customer accepts** it on a **scope**:

- Whole subscription, or  
- One resource group (narrower permission)

```mermaid
%%{init: {"theme":"base","sequenceDiagram":{"mirrorActors":false}}}%%
sequenceDiagram
  autonumber
  participant Partner as Partner tenant
  participant Offer as Offer
  participant Customer as Customer subscription
  participant Portal as Partner portal<br/>My customers
  Partner->>Offer: Write the contract card<br/>who + which roles
  Customer->>Offer: Accept on a scope<br/>(assignment)
  Partner->>Portal: Open My customers<br/>and work inside the role
```

| Piece | Plain English |
|-------|----------------|
| Offer | “Here is who we are and what roles we ask for.” |
| Assignment | “Yes — you may have those roles on **this** subscription or RG.” |

| Safer choice | Riskier choice |
|--------------|----------------|
| One **resource group** + **Reader** | Entire subscription + **Owner** |

In real designs, start narrow (one RG + least privilege). Do not grant Owner on a production ADX resource group without a strong reason.

---

## 6. After acceptance — a day in the partner’s life

Once the customer has accepted:

1. Partner engineer signs in to the **partner** tenant (normal Contoso login).  
2. Opens Azure portal → **My customers**.  
3. Selects the customer subscription.  
4. Opens the delegated resource group.  
5. Can **list** resources if the role is Reader.  
6. **Create / delete** should fail if only Reader was granted — that proves the limit works.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart LR
  U["Partner signs in<br/>to partner tenant"] --> M["My customers"]
  M --> S["Pick customer<br/>subscription"]
  S --> R["Open delegated RG"]
  R --> W["Reader: list OK"]
  R --> X["Create resource:<br/>denied"]
  style U fill:#0078D4,stroke:#005A9E,color:#fff
  style M fill:#50e6ff,stroke:#0078D4,color:#000
  style W fill:#107C10,stroke:#0B5A0B,color:#fff
  style X fill:#c50f1f,stroke:#8b0000,color:#fff
```

On the **customer** side, the relationship shows under **Service providers** (or similar Lighthouse customer blades). That is the mirror view: “who did we allow in?”

### Lifecycle (create → use → stop)

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart LR
  A["1 Define offer"] --> B["2 Customer accepts"]
  B --> C["3 Partner operates"]
  C --> D["4 Customer revokes"]
  D --> E["5 Access ends<br/>resources stay"]
  style A fill:#0078D4,stroke:#005A9E,color:#fff
  style B fill:#FFB900,stroke:#C98400,color:#000
  style C fill:#107C10,stroke:#0B5A0B,color:#fff
  style D fill:#ca5010,stroke:#8a3700,color:#fff
  style E fill:#666,stroke:#333,color:#fff
```

**Revoke ≠ delete the customer’s VMs or ADX.**  
Revoke only removes the cross-tenant permission bridge. The customer’s resources remain; the partner simply cannot manage them that way anymore.

---

## 7. How this maps to *your* ADX training

You already work in **one** training tenant (`atttraining`) and one Pay-As-You-Go subscription with ADX and per-student databases.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph TODAY["What you already use in class"]
    T["Training Entra tenant"]
    PAY["Pay-As-You-Go subscription"]
    ADX["ADX cluster adxtrainaug26"]
    DB["ADXTrainingDB_u01 … u06"]
    APP["Entra app for Logstash ingest"]
    T --> PAY --> ADX --> DB
    APP -->|"app auth to ingest"| ADX
  end
  subgraph STORY["Lighthouse story on top"]
    MSP["A partner tenant<br/>(another company)"]
    LH["Delegated Reader<br/>on a chosen scope"]
    MSP --> LH
    LH -.->|"operate / monitor<br/>without joining atttraining"| PAY
  end
  style TODAY fill:#1a3d1a,stroke:#107C10,color:#fff
  style STORY fill:#0b3d5c,stroke:#0078D4,color:#fff
  style APP fill:#ca5010,stroke:#8a3700,color:#fff
  style LH fill:#50e6ff,stroke:#0078D4,color:#000
```

| What you did in Modules 01–08 | Is that Lighthouse? |
|-------------------------------|---------------------|
| Ingest logs from S3 / Logstash / GuardDuty into ADX | **No** — that is **data** moving into ADX |
| Entra app + secret for the kusto plugin | **No** — that is **app authentication** for ingest |
| A partner company operating many customers’ Azure (including ADX RGs) from its own tenant | **Yes** — that is the Lighthouse **ops** story |

So: this module does not change how you ingest. It answers a governance question: *how would a partner manage Azure across customers cleanly?*

---

## 8. Checkpoint — can you explain it simply?

Try answering in plain words (no jargon dump):

1. Who **owns** the subscription after a Lighthouse delegation?  
2. Does Lighthouse make the partner a **Global Admin** of the customer Entra ID?  
3. What is an **offer**? What is an **assignment**?  
4. Guest user vs Lighthouse — which scales better for 100 customers?  
5. Why is **Reader** on one resource group safer than **Owner** on the whole ADX resource group?  
6. Is the Logstash Entra app the same thing as Lighthouse? Why or why not?

---

## 9. One-slide summary

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  S["Azure Lighthouse"]
  S --> S1["Cross-tenant"]
  S --> S2["Azure RBAC only"]
  S --> S3["Customer keeps ownership"]
  S --> S4["Partner stays in own Entra"]
  S --> S5["Offer + assignment"]
  S --> S6["My customers / Service providers"]
  style S fill:#0078D4,stroke:#005A9E,color:#fff
  style S1 fill:#50e6ff,stroke:#0078D4,color:#000
  style S2 fill:#50e6ff,stroke:#0078D4,color:#000
  style S3 fill:#107C10,stroke:#0B5A0B,color:#fff
  style S4 fill:#107C10,stroke:#0B5A0B,color:#fff
  style S5 fill:#FFB900,stroke:#C98400,color:#000
  style S6 fill:#FFB900,stroke:#C98400,color:#000
```

**One sentence to keep:**  
*Lighthouse lets a partner manage Azure resources in a customer subscription by delegated roles, without moving identities into the customer tenant and without taking ownership away from the customer.*
