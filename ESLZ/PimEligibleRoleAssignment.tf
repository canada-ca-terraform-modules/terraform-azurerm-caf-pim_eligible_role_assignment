terraform {
  required_version = ">= 1.9"
}

variable "pim_rbac" {
  description = "List of PIM eligible role assignment configurations"
  type        = any
  default     = []
}

module "pim_eligible_role_assignment" {
  source = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-pim_eligible_role_assignment?ref=v1.1.0"
  # NOTE: for_each is keyed on role.role (the role name). If pim_rbac contains two
  # entries with the same role name (e.g. two separate "Reader" assignments to
  # different scopes/principals), the second entry silently overwrites the first
  # in this map. Give each entry a distinct role name, or merge multiple
  # scope/principal combinations into a single entry's scope/principal_id lists.
  for_each = { for role in try(var.pim_rbac, []) : role.role => role }

  scope                        = try(each.value.scope, [])
  principal_id                 = each.value.principal_id
  role_definition              = each.key
  pim_eligible_role_assignment = each.value
}
