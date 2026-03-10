---
name: terraform-validation-workflow
description: Run the standard validation workflow for this Terraform module repository when users ask to validate, lint, run checks, or verify Terraform changes.
---

# Terraform Validation Workflow (Module Repo)

Use this workflow whenever validating changes in this repository.

## Required sequence

1. Validate at repo root:
   - `terraform init -backend=false`
   - `terraform validate`

2. Validate in `ESLZ/`:
   - `terraform init -backend=false`
   - `terraform validate`

3. Lint recursively from repo root:
   - `tflint --recursive`

## Execution guidance

- Run commands in the exact order above.
- Stop immediately on first hard failure and report the failing command and error.
- If `ESLZ` fails due to module source resolution, report the source path and suggest
  a local-path source for local validation.
- Keep changes minimal and do not modify unrelated files while validating.

## Success criteria

- Root `terraform validate` passes.
- `ESLZ/terraform validate` passes.
- `tflint --recursive` returns no issues.
