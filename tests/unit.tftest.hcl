# Unit tests for locals.tf logic — no Azure credentials needed.
# Requires Terraform >= 1.7 (mock_provider support).
# Run blocks default to command = apply; individual runs override with
# command = plan where noted (required for expect_failures to work correctly -
# see https://developer.hashicorp.com/terraform/language/tests#expecting-failures).

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
    condition     = contains(keys(azurerm_pim_eligible_role_assignment.this), "principal0-custom-alpha")
    error_message = "Key should use custom_scope_names[0] ('custom-alpha'), not basename(scope)"
  }

  assert {
    condition     = contains(keys(azurerm_pim_eligible_role_assignment.this), "principal0-custom-beta")
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
    condition     = contains(keys(azurerm_pim_eligible_role_assignment.this), "principal0-rg-gamma")
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
    condition     = azurerm_pim_eligible_role_assignment.this["principal0-rg-alpha"].justification == "Eligible assignment for project operations"
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
    condition     = azurerm_pim_eligible_role_assignment.this["principal0-rg-alpha"].condition_version == "2.0"
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
    condition     = length(azurerm_pim_eligible_role_assignment.this["principal0-rg-alpha"].ticket) == 1
    error_message = "ticket block should be emitted when set"
  }

  assert {
    condition     = azurerm_pim_eligible_role_assignment.this["principal0-rg-alpha"].ticket[0].number == "INC0012345"
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
    condition     = azurerm_pim_eligible_role_assignment.this["principal0-rg-alpha"].schedule[0].start_date_time == "2026-03-06T00:00:00Z"
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
    condition     = length(azurerm_pim_eligible_role_assignment.this["principal0-rg-alpha"].schedule) == 1
    error_message = "schedule block should be emitted when expiration.duration_hours is set"
  }

  assert {
    condition     = azurerm_pim_eligible_role_assignment.this["principal0-rg-alpha"].schedule[0].expiration[0].duration_hours == 8
    error_message = "expiration.duration_hours should be passed through to the resource"
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
    condition     = length(azurerm_pim_eligible_role_assignment.this["principal0-rg-alpha"].schedule) == 1
    error_message = "schedule block should be emitted when expiration.end_date_time is set"
  }

  assert {
    condition     = azurerm_pim_eligible_role_assignment.this["principal0-rg-alpha"].schedule[0].expiration[0].end_date_time == "2027-03-06T00:00:00Z"
    error_message = "expiration.end_date_time should be passed through to the resource"
  }
}

###############################################################################
# 12. custom_scope_names / scope length mismatch silently falls back to
#     basename(scope) - documents existing (non-breaking) behavior; a hard
#     validation error here would break callers who currently rely on this
#     fallback, so it is intentionally not enforced.
###############################################################################

run "custom_scope_names_length_mismatch_falls_back_to_basename" {
  variables {
    principal_id = ["aaaaaaaa-0000-0000-0000-000000000001"]
    scope = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha",
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-beta",
    ]
    custom_scope_names = ["only-one-name"]
    role_definition    = "Reader"
  }

  assert {
    condition     = contains(keys(azurerm_pim_eligible_role_assignment.this), "principal0-rg-alpha")
    error_message = "Mismatched custom_scope_names length should fall back to basename(scope) rather than erroring"
  }

  assert {
    condition     = contains(keys(azurerm_pim_eligible_role_assignment.this), "principal0-rg-beta")
    error_message = "Mismatched custom_scope_names length should fall back to basename(scope) rather than erroring"
  }
}

###############################################################################
# 13. principal_id validation rejects non-GUID values
###############################################################################

run "principal_id_rejects_non_guid" {
  command = plan

  variables {
    principal_id    = ["not-a-guid"]
    scope           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alpha"]
    role_definition = "Reader"
  }

  expect_failures = [
    var.principal_id,
  ]
}
