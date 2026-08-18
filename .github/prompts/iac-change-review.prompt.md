---
mode: ask
description: Review Terraform changes for safety, compatibility, and validation gaps.
---
You are reviewing Terraform changes in this repository.

Goals:
1. Identify security risks, blast-radius issues, and destructive changes.
2. Identify backward-compatibility risks in variables, outputs, and modules.
3. Identify missing validation, tests, and documentation updates.
4. Propose a concise remediation plan.

Review method:
- Summarize changed files and likely behavior impact.
- List findings ordered by severity: high, medium, low.
- For each finding include: file, reason, potential impact, and exact fix.
- If no findings, state "No material findings" and list residual risks.

Validation expectations:
- Terraform formatting and validation.
- Example tfvars and docs alignment.
- Security controls and least privilege.

Output sections:
1. Findings
2. Suggested Fixes
3. Validation Commands
4. Residual Risks
