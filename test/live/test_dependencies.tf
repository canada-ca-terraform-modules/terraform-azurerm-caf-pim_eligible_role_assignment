# test_dependencies.tf
# Self-contained dependency resources, owned entirely by this harness.
#
# Deliberately NOT reusing any shared/production resource group: writing into
# a shared RG usually requires elevated, non-sandbox permissions. A dedicated
# throwaway RG here needs only Contributor + User Access Administrator on the
# sandbox subscription and can never collide with or affect any production
# resource.
#
# Principal for the eligible role assignment: Azure PIM eligible assignments
# (as opposed to plain/active azurerm_role_assignment) only support User or
# Group principals, never a Service Principal - confirmed via a live apply
# attempt against the CI identity itself, which failed with
# "RoleAssignmentNotSupported: Role assignment is not supported" (400). Fixed
# by creating a dedicated, empty Entra ID group instead and using its
# object_id as the eligible principal - a Group needs no members for the
# eligible *assignment* to succeed; membership only matters later when
# someone actually activates it.
#
# IMPORTANT - two-step apply required (same constraint live-test.yml's
# "Baseline apply" / "PR apply" steps rely on): the module's own for_each key
# is "${principal_id}-${scope_name}" (see main.tf's custom_scope_names
# comment). If azuread_group.live_test is created in the SAME apply as the
# PIM module, principal_id is "(known after apply)" and Terraform can't
# compute the for_each map's keys ("Invalid for_each argument"). CI relies on
# a single `terraform apply` succeeding in one shot, so this harness avoids
# the problem structurally: azurerm_resource_group.live_test and
# azuread_group.live_test have no dependency on the PIM module itself, and
# Terraform's own graph naturally creates them before evaluating the
# module's for_each in the same apply - only an explicit same-apply
# dependency (e.g. an inline reference the other direction) could reintroduce
# the "known after apply" trap. See the L2 upgrade-probe harness this was
# derived from for the manual two-step `-target=...` sequence used when
# iterating locally.

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "live_test" {
  # PR-number suffix keeps two concurrently open PRs against this module from
  # colliding on the same sandbox resource group.
  name     = "${var.env}-caf-pim-eligible-role-assignment-live-test-${var.pr_number}-rg"
  location = var.location

  # pr-number tag: lets the nightly orphan sweeper find this RG by tag and
  # match it back to a PR, independent of naming convention.
  # repository tag: the sandbox subscription is shared across module repos,
  # so the sweeper must scope its `pr-number` matches to only this repo's own
  # PRs - otherwise a PR number collision across repos could misclassify (or
  # destroy) another repo's live resource group.
  tags = {
    "pr-number"  = var.pr_number
    "repository" = var.repository
  }
}

resource "azuread_group" "live_test" {
  display_name     = "${var.env}-caf-pim-eligible-role-assignment-live-test-${var.pr_number}-group"
  security_enabled = true
  owners           = [data.azurerm_client_config.current.object_id]
}
