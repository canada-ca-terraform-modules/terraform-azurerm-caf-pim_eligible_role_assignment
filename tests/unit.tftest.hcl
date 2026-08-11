# Unit tests for locals.tf logic — no Azure credentials needed.
# Requires Terraform >= 1.7 (mock_provider support).
# All run blocks default to command = plan.

mock_provider "azurerm" {}
mock_provider "time" {}

###############################################################################
# 1. Cartesian product: 2 principals × 2 scopes → 4 assignments
###############################################################################

run "cartesian_product_2x2" {
  variables {
    principal_id = [
      "aaaaaaaa-0000-0000-0000-000000000001",
      "aaaaaaaa-0000-0000-0000-000000000002",
    ]
    scope = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha",
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-beta",
    ]
    role_definition = "Reader"
  }

  assert {
    condition     = length(azurerm_pim_eligible_role_assignment.this) == 4
    error_message = "Expected 4 assignments (2 principals × 2 scopes), got ${length(azurerm_pim_eligible_role_assignment.this)}"
  }
}

###############################################################################
# 2. custom_scope_names overrides basename(scope) as for_each key
###############################################################################

run "custom_scope_names_override_key" {
  variables {
    principal_id = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha",
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-beta",
    ]
    custom_scope_names = ["custom-alpha", "custom-beta"]
    role_definition    = "Reader"
  }

  assert {
    condition     = contains(keys(azurerm_pim_eligible_role_assignment.this), "aaaaaaaa-0000-0000-0000-000000000001-custom-alpha")
    error_message = "Key should use custom_scope_names[0] ('custom-alpha'), not basename(scope)"
  }

  assert {
    condition     = contains(keys(azurerm_pim_eligible_role_assignment.this), "aaaaaaaa-0000-0000-0000-000000000001-custom-beta")
    error_message = "Key should use custom_scope_names[1] ('custom-beta'), not basename(scope)"
  }
}

###############################################################################
# 3. basename(scope) used as key when custom_scope_names is not provided
###############################################################################

run "basename_fallback_without_custom_scope_names" {
  variables {
    principal_id    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-gamma"]
    role_definition = "Reader"
  }

  assert {
    condition     = contains(keys(azurerm_pim_eligible_role_assignment.this), "aaaaaaaa-0000-0000-0000-000000000001-rg-gamma")
    error_message = "Key should use basename(scope) = 'rg-gamma' when custom_scope_names is empty"
  }
}

###############################################################################
# 4. role_definition as full resource ID → no data source lookup
###############################################################################

run "role_definition_full_id_no_lookup" {
  variables {
    principal_id    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha"]
    role_definition = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
  }

  assert {
    condition     = length(data.azurerm_role_definition.this) == 0
    error_message = "No data source lookup expected when role_definition contains '/roleDefinitions/'"
  }
}

###############################################################################
# 5. role_definition as display name → data source lookup fires
###############################################################################

run "role_definition_name_triggers_lookup" {
  variables {
    principal_id    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha"]
    role_definition = "Reader"
  }

  assert {
    condition     = length(data.azurerm_role_definition.this) == 1
    error_message = "Expected data source lookup when role_definition is a display name"
  }
}

###############################################################################
# 6. justification is passed through to the resource
###############################################################################

run "justification_set" {
  variables {
    principal_id    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha"]
    role_definition = "Reader"
    pim_eligible_role_assignment = {
      justification = "Eligible assignment for project operations"
    }
  }

  assert {
    condition     = azurerm_pim_eligible_role_assignment.this["aaaaaaaa-0000-0000-0000-000000000001-rg-alpha"].justification == "Eligible assignment for project operations"
    error_message = "justification should be passed through to the resource"
  }
}

###############################################################################
# 7. condition and condition_version are passed through together
###############################################################################

run "condition_and_condition_version_set" {
  variables {
    principal_id    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha"]
    role_definition = "Reader"
    pim_eligible_role_assignment = {
      condition         = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase 'example-container'"
      condition_version = "2.0"
    }
  }

  assert {
    condition     = azurerm_pim_eligible_role_assignment.this["aaaaaaaa-0000-0000-0000-000000000001-rg-alpha"].condition_version == "2.0"
    error_message = "condition_version should be passed through to the resource"
  }
}

###############################################################################
# 8. ticket block is passed through
###############################################################################

run "ticket_block_set" {
  variables {
    principal_id    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha"]
    role_definition = "Reader"
    pim_eligible_role_assignment = {
      ticket = {
        number = "INC0012345"
        system = "ServiceNow"
      }
    }
  }

  assert {
    condition     = length(azurerm_pim_eligible_role_assignment.this["aaaaaaaa-0000-0000-0000-000000000001-rg-alpha"].ticket) == 1
    error_message = "ticket block should be emitted when set"
  }

  assert {
    condition     = azurerm_pim_eligible_role_assignment.this["aaaaaaaa-0000-0000-0000-000000000001-rg-alpha"].ticket[0].number == "INC0012345"
    error_message = "ticket.number should be passed through to the resource"
  }
}

###############################################################################
# 9. schedule.start_date_time explicit value bypasses time_static
###############################################################################

run "schedule_explicit_start_date_time" {
  variables {
    principal_id    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha"]
    role_definition = "Reader"
    pim_eligible_role_assignment = {
      schedule = {
        start_date_time = "2026-03-06T00:00:00Z"
      }
    }
  }

  assert {
    condition     = length(time_static.start_date_time) == 0
    error_message = "time_static.start_date_time should not be created when start_date_time is explicitly set"
  }

  assert {
    condition     = azurerm_pim_eligible_role_assignment.this["aaaaaaaa-0000-0000-0000-000000000001-rg-alpha"].schedule[0].start_date_time == "2026-03-06T00:00:00Z"
    error_message = "explicit start_date_time should be passed through to the resource"
  }
}

###############################################################################
# 10. schedule.expiration.duration_hours
###############################################################################

run "schedule_expiration_duration_hours" {
  variables {
    principal_id    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha"]
    role_definition = "Reader"
    pim_eligible_role_assignment = {
      schedule = {
        expiration = {
          duration_hours = 8
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_pim_eligible_role_assignment.this["aaaaaaaa-0000-0000-0000-000000000001-rg-alpha"].schedule) == 1
    error_message = "schedule block should be emitted when expiration.duration_hours is set"
  }
}

###############################################################################
# 11. schedule.expiration.end_date_time
###############################################################################

run "schedule_expiration_end_date_time" {
  variables {
    principal_id    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha"]
    role_definition = "Reader"
    pim_eligible_role_assignment = {
      schedule = {
        expiration = {
          end_date_time = "2027-03-06T00:00:00Z"
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_pim_eligible_role_assignment.this["aaaaaaaa-0000-0000-0000-000000000001-rg-alpha"].schedule) == 1
    error_message = "schedule block should be emitted when expiration.end_date_time is set"
  }
}
