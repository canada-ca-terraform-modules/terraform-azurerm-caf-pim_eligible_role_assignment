# Upgrade compatibility test — state-chaining pattern.
# Purpose: verify that the module's for_each keys remain stable when optional
# arguments are added to an existing assignment (no unexpected replacements).
#
# Note: all azurerm_pim_eligible_role_assignment arguments are ForceNew.
# mock_provider ignores ForceNew, so force-new attributes appear as in-place
# updates here. A real plan with credentials is required to detect ForceNew
# regressions in CI against live Azure.

mock_provider "azurerm" {
  # data.azurerm_role_definition.this[0].id must look like a real ARM ID
  # (starts with "/") to satisfy the resource's lifecycle precondition -
  # mock_provider otherwise generates an arbitrary 8-char string for it.
  mock_data "azurerm_role_definition" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    }
  }
}
mock_provider "time" {}

# Step 1 — apply baseline assignment (no optional args set).
run "baseline_apply" {
  command = apply

  variables {
    principal_id    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"]
    role_definition = "Reader"
  }

  assert {
    condition     = contains(keys(azurerm_pim_eligible_role_assignment.this), "principal0-rg-test")
    error_message = "Baseline apply: expected key 'principal0-rg-test'"
  }
}

# Step 2 — plan against baseline state with optional args added.
# The resource key must not change; the plan must show 0 destroys.
run "upgrade_plan_no_replacement" {
  command = plan

  variables {
    principal_id    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"]
    role_definition = "Reader"
    pim_eligible_role_assignment = {
      justification = "Eligible assignment for project operations"
      schedule = {
        expiration = {
          duration_days = 30
        }
      }
    }
  }

  assert {
    condition     = contains(keys(azurerm_pim_eligible_role_assignment.this), "principal0-rg-test")
    error_message = "Upgrade plan: assignment key must remain stable after adding optional args"
  }
}
