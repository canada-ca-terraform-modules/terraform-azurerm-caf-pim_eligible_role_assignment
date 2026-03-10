data "azurerm_subscription" "current" {}

data "azurerm_role_definition" "this" {
  count = local.role_definition_type == "name" ? 1 : 0
  name  = var.role_definition
  scope = local.effective_scope[0]
}

resource "time_static" "start_date_time" {
  for_each = (
    try(var.pim_eligible_role_assignment.schedule, null) != null &&
    try(var.pim_eligible_role_assignment.schedule.start_date_time, null) == null
    ) ? {
    for assignment in local.assignments : "${assignment.principal_id}-${assignment.scope_name}" => assignment
  } : {}
}

resource "azurerm_pim_eligible_role_assignment" "this" {
  for_each = { for assignment in local.assignments : "${assignment.principal_id}-${assignment.scope_name}" => assignment }

  scope = each.value.scope
  role_definition_id = local.role_definition_type == "id" ? var.role_definition : (
    startswith(data.azurerm_role_definition.this[0].id, "/subscriptions/") || startswith(data.azurerm_role_definition.this[0].id, "/providers/")
    ? data.azurerm_role_definition.this[0].id
    : "${each.value.scope}${data.azurerm_role_definition.this[0].id}"
  )
  principal_id = each.value.principal_id

  # Optional parameters
  justification     = try(var.pim_eligible_role_assignment.justification, null)
  condition         = try(var.pim_eligible_role_assignment.condition, null)
  condition_version = try(var.pim_eligible_role_assignment.condition_version, null)

  # Optional schedule block
  dynamic "schedule" {
    for_each = try(var.pim_eligible_role_assignment.schedule, null) != null ? [1] : []
    content {
      start_date_time = try(var.pim_eligible_role_assignment.schedule.start_date_time, time_static.start_date_time[each.key].rfc3339)

      dynamic "expiration" {
        for_each = try(var.pim_eligible_role_assignment.schedule.expiration, null) != null ? [1] : []
        content {
          duration_days  = try(var.pim_eligible_role_assignment.schedule.expiration.duration_days, null)
          duration_hours = try(var.pim_eligible_role_assignment.schedule.expiration.duration_hours, null)
          end_date_time  = try(var.pim_eligible_role_assignment.schedule.expiration.end_date_time, null)
        }
      }
    }
  }

  # Optional ticket block
  dynamic "ticket" {
    for_each = try(var.pim_eligible_role_assignment.ticket, null) != null ? [1] : []
    content {
      number = try(var.pim_eligible_role_assignment.ticket.number, null)
      system = try(var.pim_eligible_role_assignment.ticket.system, null)
    }
  }

  timeouts {
    create = "30m"
    read   = "5m"
    delete = "30m"
  }
}
