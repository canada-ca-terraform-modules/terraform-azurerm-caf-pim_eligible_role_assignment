terraform {
  required_version = ">= 1.9"
}

variable "pim_rbac" {
  description = "List of PIM eligible role assignment configurations"
  type        = any
  default     = []
}

module "pim_eligible_role_assignment" {
  source   = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-pim_eligible_role_assignment?ref=v1.0.0"
  for_each = { for role in try(var.pim_rbac, []) : role.role => role }

  scope                        = try(each.value.scope, [])
  principal_id                 = each.value.principal_id
  role_definition              = each.key
  pim_eligible_role_assignment = each.value
}
