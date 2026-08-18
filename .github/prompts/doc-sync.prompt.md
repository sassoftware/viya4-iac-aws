---
mode: ask
description: Detect and propose documentation updates based on code changes.
---
Analyze repository changes and identify required documentation updates.

Checklist:
- Variables changed in Terraform or Ansible inputs.
- Outputs or behavior changed.
- New prerequisites, permissions, or limits.
- Example files requiring updates.

Return:
1. Required documentation file updates.
2. Exact suggested text or bullets for each file.
3. Any open questions that block documentation accuracy.
