# How we work — Module 09 (Azure Lighthouse)

Same Entra / Azure portal access as ADX labs (Pay-As-You-Go). No AWS VM required for this module.

## Start here

```bash
cd ~/adx-aws-training
ls Module_09_Azure_Lighthouse assets/module_09
```

Open the **Azure portal** signed into the training directory.

## Reading order

1. `09_Azure_Lighthouse_Primer.md`  
2. `09_Azure_Lighthouse_Concepts.md`  
3. `09_Azure_Lighthouse_Lab.md` — portal walk + offer template + optional trainer demo  
4. `09_Exercises.md`

## Remember

- Lighthouse = **cross-tenant Azure RBAC by delegation** (not guests, not Logstash app auth)  
- Practical is **portal + discussion**; full two-tenant deploy is optional trainer demo  
- Prefer **Reader** on a demo RG — never practice Owner on the ADX resource group
