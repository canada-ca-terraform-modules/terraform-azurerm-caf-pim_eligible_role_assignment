# `test/live/` - live-test harness

A live, real-Azure-resource harness used by the `live-test` PR check (see
the [`live-test-actions`](https://github.com/canada-ca-terraform-modules/live-test-actions)
repo and this module's own `.github/workflows/live-test.yml`) to prove that
an open PR doesn't destroy or replace a resource a real consumer already
has running. It is **not** a substitute for either of the module's other
two test surfaces:

- **`tests/*.tftest.hcl`** - mock-based unit tests (`terraform test`, no
  provider credentials, no live Azure resources). Covers naming, defaults,
  and validation logic on every PR via `terraform-ci.yml`. Run these first;
  they're fast and free.
- **`ESLZ/`** - a usage example showing the map-based blueprint pattern
  consumers actually wire this module into. Not exercised by CI at all;
  documentation only.
- **`test/live/`** (this directory) - a single, real instance of the module
  applied against a disposable Azure sandbox subscription. Used by CI to
  diff the PR's plan against a live baseline, and can be run manually by a
  maintainer the same way.

## What's here

| File | Purpose |
|---|---|
| `main.tf` | Module block with `source = "../../"` (a relative path, not a pinned `?ref` - "baseline" and "PR" are just two on-disk checkouts of this repo), the `azurerm`/`azuread` provider config, and an empty `backend "local" {}` block (path supplied at `init` time - see below). |
| `test_dependencies.tf` | A dedicated, throwaway resource group **and** a dedicated Entra ID group, both owned outright by this harness - never a shared/production resource. Names are suffixed with `var.pr_number` so concurrently open PRs never collide. |
| `variables.tf` | `env`, `location` (defaults to `canadacentral`), `pr_number` (defaults to `"manual"`), `repository`, and `role_definition` (defaults to `"Reader"`). |
| `config/pim_eligible_role_assignment.tfvars` | One representative real-usage fixture: a single eligible `Reader` role assignment, scoped to the throwaway resource group, with a 30-day expiration schedule. |

No Terragrunt anywhere under this directory - a single harness per repo has
no cross-harness DRY need.

## Module-specific caveats

- **The eligible role's principal must be a User or Group, never a Service
  Principal.** Azure PIM eligible assignments (as opposed to plain/active
  `azurerm_role_assignment`) reject a Service Principal principal with
  `RoleAssignmentNotSupported: Role assignment is not supported` (400).
  `test_dependencies.tf` creates a dedicated, empty Entra ID group
  (`azuread_group.live_test`) instead of using the CI identity's own
  `object_id` directly - a Group needs no members for the eligible
  *assignment* to succeed; membership only matters later when someone
  actually activates it. This also means the CI identity needs Entra ID
  group-create permission (Graph), in addition to Contributor + User Access
  Administrator on the sandbox subscription.
- **`custom_scope_names` is required.** The module's own `for_each` key is
  `"${principal_id}-${scope_name}"`, and `scope_name` defaults to
  `basename(scope)` - but `scope` here is a resource group created in this
  same TF invocation, so `basename(scope)` is unknown until apply.
  `custom_scope_names = ["probe"]` in `main.tf` sidesteps that; per the
  module's own variable description, `custom_scope_names` is required
  whenever the scope is being created in the same TF invocation.
- **`principal_id` must be known before the module's `for_each` runs.** If
  `azuread_group.live_test` depended on the PIM module (or vice versa) in
  the same apply, `principal_id` would be `(known after apply)` and
  Terraform couldn't compute the `for_each` map's keys
  (`Invalid for_each argument`). This harness avoids that structurally - the
  dependency resources have no dependency on the PIM module, so Terraform's
  own graph creates them first within the same `terraform apply` that
  `live-test.yml` runs.

## Running it manually

Requires your own `az login` session against the sandbox subscription.

```bash
cd test/live
terraform init
terraform plan  -var-file=config/pim_eligible_role_assignment.tfvars
terraform apply -var-file=config/pim_eligible_role_assignment.tfvars
```

Confirm only the live-test resource group, the live-test Entra ID group, and
`module.pim_eligible_role_assignment` are planned/applied, then tear it down:

```bash
terraform destroy -var-file=config/pim_eligible_role_assignment.tfvars
```

No `.tfstate` file is ever committed under `test/live/` - every run is
fully ephemeral, whether run by CI or by hand.

## Two-checkout state isolation (baseline vs. PR)

CI proves a PR isn't a breaking change by applying the target branch as a
live baseline, then plan/apply-ing the PR branch's checkout of this same
harness against that same live state - two on-disk checkouts of this repo,
one shared external state file, no state copying between them:

```bash
# Directory A: PR branch checkout, directory B: target branch checkout.
STATE=$RUNNER_TEMP/live-test-<pr-number>.tfstate

# 1. Baseline apply, from B.
cd B/test/live
terraform init -backend-config="path=$STATE"
terraform apply -var-file=config/pim_eligible_role_assignment.tfvars -var="pr_number=<pr-number>"

# 2. PR plan (and, in CI, apply), from A, against the same state file.
cd A/test/live
terraform init -backend-config="path=$STATE"
terraform plan -var-file=config/pim_eligible_role_assignment.tfvars -var="pr_number=<pr-number>"

# 3. Always tear down from A once the run finishes (`if: always()` in CI).
terraform destroy -var-file=config/pim_eligible_role_assignment.tfvars -var="pr_number=<pr-number>"
```

`pr_number` (`TF_VAR_pr_number` in CI, sourced from `github.event.number`)
suffixes every `test_dependencies.tf` resource name, so two concurrently
open PRs against this module - each pointed at their own
`live-test-<pr-number>.tfstate` - never collide on the same sandbox resource
group or Entra ID group.
