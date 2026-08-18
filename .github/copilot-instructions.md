# Copilot Instructions for viya4-iac-aws

## Mission
This repository provisions SAS Viya infrastructure on AWS using Terraform. Prioritize safety, repeatability, and least-privilege designs.

## Engineering Rules
- Prefer minimal, focused Terraform changes with no unrelated formatting churn.
- Preserve backward compatibility for input variables, outputs, and module interfaces unless explicitly requested.
- Keep region, network, IAM, and security decisions explicit and reviewable.
- Never introduce hard-coded credentials, account IDs, keys, or secrets.
- Favor deterministic resources and idempotent logic.

## Validation Expectations
- Run `terraform fmt -check` and `terraform validate` where possible.
- Keep examples and docs in sync with behavior changes.
- If variables or outputs change, update docs under `docs/` and sample tfvars under `examples/`.

## Pull Request Checklist
- What changed and why.
- Security and blast-radius notes.
- Compatibility notes for module consumers.
- Test and validation evidence.

## Agent Guardrails
- Do not perform destructive actions by default.
- Ask for explicit approval before risky operations or breaking interface changes.
- If assumptions are required, state them clearly in the PR summary.
