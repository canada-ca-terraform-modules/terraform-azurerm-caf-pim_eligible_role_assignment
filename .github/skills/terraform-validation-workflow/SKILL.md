---
name: terraform-validation-workflow
description: Run the standard validation workflow for this Terraform module repository. Trigger when users ask to "validate", "lint", "run checks", "verify Terraform changes", "check this module", or "run terraform validation".
---

# Terraform Validation Workflow (Module Repo)

Use this workflow whenever validating changes in this repository.

## Required sequence

1. Validate at repo root:
   - `terraform init -backend=false`
   - `terraform validate`

2. Validate in `test/`:
   - `terraform init -backend=false`
   - `terraform validate`

3. Lint recursively from repo root:
   - `tflint --recursive`

## Execution guidance

- Run commands in the exact order above.
- Stop immediately on first hard failure and report the failing command and error.
- Keep `ESLZ/` as an implementation example for consumers and do not rely on it for
   local module validation.
- Keep changes minimal and do not modify unrelated files while validating.

## Success criteria

- Root `terraform validate` passes.
- `terraform validate` in `test/` passes.
- `tflint --recursive` returns no issues.
