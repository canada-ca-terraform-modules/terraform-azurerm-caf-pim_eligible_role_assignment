# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.0] - 2026-08-11

### Changed

- Bumped `azurerm` provider constraint from `~> 4.0` to `~> 5.0`, pinned and
  tested against `azurerm` `5.0.1`.
- Bumped `ESLZ/PimEligibleRoleAssignment.tf` module ref from `v1.0.0` to `v1.1.0`.
- Updated GitHub Actions pins: `actions/checkout` `v6.0.2` -> `v7.0.1`,
  `hashicorp/setup-terraform` `v4.0.0` -> `v4.0.1`,
  `terraform-linters/setup-tflint` `v6.2.2` -> `v6.3.0`
  (`tflint_version` `v0.61.0` -> `v0.64.0`).
- Relaxed `required_version` from `>= 1.9` to `>= 1.7` — the module uses no
  language feature newer than 1.7, and 1.7 is the actual minimum needed for
  `mock_provider`/`terraform test` support used by this module's own tests.
- `.github/workflows/release.yml` no longer hardcodes `master`: both the
  release-on-merge trigger and the checkout/release target now resolve the
  PR's actual base branch (`${{ github.event.pull_request.base.ref }}`), and
  the trigger watches both `main` and `master` to match `terraform-ci.yml`.

### Added

- `.gitattributes` enforcing `eol=lf` on all text files.
- `.github/workflows/release.yml` — creates a GitHub release on merge to
  `main`/`master`, tagged with the version pinned in
  `ESLZ/PimEligibleRoleAssignment.tf`'s `?ref=`.
- `tests/unit.tftest.hcl`: added coverage for every pre-existing optional
  argument/block the resource exposes (`justification`, `condition` +
  `condition_version`, `ticket`, explicit `schedule.start_date_time`,
  `schedule.expiration.duration_hours`, `schedule.expiration.end_date_time`) —
  previously only `schedule.expiration.duration_days` was exercised
  (via `upgrade_compat.tftest.hcl`).
- A `lifecycle.precondition` on `azurerm_pim_eligible_role_assignment.this`
  guarding the `role_definition_id` scope-concatenation fallback: fails fast
  with a clear error if `data.azurerm_role_definition.this[0].id` ever stops
  starting with `/`, instead of silently building a malformed ID.
- A `validation` block on `principal_id` rejecting non-GUID values at plan
  time instead of failing later with a cryptic Azure API error.
- A code comment on `ESLZ/PimEligibleRoleAssignment.tf` documenting that
  `for_each` keys on `role.role` and duplicate role names in `pim_rbac`
  silently overwrite each other.
- Test coverage for the `custom_scope_names`/`scope` length-mismatch fallback
  and for the new `principal_id` GUID validation. 7 -> 15 total test runs.

### Removed

- `test/` directory (`PimEligibleRoleAssignment.tf`, `versions.tf`) and
  `.github/copilot-instructions.md` — legacy scaffolding not part of the
  ESLZ convention; `ESLZ/*.tf` + `tests/*.tftest.hcl` are the supported
  usage/test surface for this module.

### Notes

- Gap analysis against the `azurerm` `5.0.1` provider schema found no breaking
  changes affecting this module: `azurerm_pim_eligible_role_assignment`,
  `data.azurerm_role_definition`, and `data.azurerm_subscription` schemas are
  unchanged between `4.63.0` and `5.0.1` for every argument this module uses.
- The provider's 5.0 upgrade guide documents a behavioural change to
  `data.azurerm_role_definition`'s `role_definition_id` output attribute
  (now returns a bare UUID instead of a full Resource Manager ID when looked
  up by `name`). This module only reads `data.azurerm_role_definition.this[0].id`,
  not `.role_definition_id`, so it is unaffected.
- No caller-facing changes; existing `ESLZ/*.tfvars` configurations remain
  valid with no plan diff expected from this upgrade alone.

## [1.0.0]

### Changed

- Upgraded `azurerm` provider constraint to `~> 4.0` (previously unconstrained
  above the documented `>= 4.63.0` floor).
- Added `sensitive = true` to the `pim_eligible_role_assignments` output.
- Replaced `.tflint.hcl`'s deprecated `module` attribute with
  `call_module_type` for tflint `>= v0.54.0` compatibility.
- Updated GitHub Actions workflow pins to their latest versions at the time.

### Added

- Native `terraform test` coverage (`tests/unit.tftest.hcl`).
