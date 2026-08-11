variable "scope" {
  description = "IDs for the resources where the PIM eligible role will be assigned. Defaults to current subscription if not provided."
  type        = list(string)
  default     = []
}

variable "custom_scope_names" {
  description = "List of names to use instead of the scopes for naming TF resources. This is required if the scope is being created in the same TF invocation."
  type        = list(string)
  default     = []
}

variable "principal_id" {
  description = "IDs for the principals (User, Group, Service Principal) to assign the eligible role to"
  type        = list(string)

  validation {
    condition     = alltrue([for id in var.principal_id : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))])
    error_message = "Each principal_id must be a valid GUID (Azure AD Object ID), e.g. 00000000-0000-0000-0000-000000000000."
  }
}

variable "role_definition" {
  description = "Name or ID of the RBAC role being assigned as PIM eligible"
  type        = string
}

variable "pim_eligible_role_assignment" {
  description = "Object containing all optional parameters for the PIM eligible role assignment"
  type        = any
  default     = {}
}
