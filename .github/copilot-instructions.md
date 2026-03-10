# Copilot Instructions for terraform-azurerm-caf-role-assignment

## Module behavior to preserve
- `scope` is a `list(string)` and should contain full Azure resource IDs.
- `principal_id` is consumed as a list in locals and assignment expansion logic.
- `basename(scope)` is used for Terraform resource key naming only, not as Azure scope input.

## Validation and lint workflow
- For this module repo, run validation with backend disabled:
  - `terraform init -backend=false`
  - `terraform validate`
- Validate both directories when making changes:
  - repo root
  - `ESLZ/`
- Run lint recursively from root:
  - `tflint --recursive`
- Repo skill for this workflow:
  - `.github/skills/terraform-validation-workflow/SKILL.md`

## Version constraints
- Keep Terraform and provider constraints in `versions.tf` files:
  - root `versions.tf` should define `required_version` and `required_providers.azurerm`
  - `ESLZ/versions.tf` should define `required_version`

## Repository hygiene
- Do not commit generated Terraform working directories:
  - `.terraform/` (any level)
- Keep `.gitignore` rules aligned with module-repo expectations.
- Keep `ESLZ/PimEligibleRoleAssignment.tfvars` tracked as an example file.

## Documentation expectations
- README examples must match actual variable types (`scope` list, `principal_id` list).
- Prefer minimal, targeted changes and keep examples consistent with module behavior.
