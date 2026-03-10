locals {
  role_definition_type = strcontains(var.role_definition, "/roleDefinitions/") ? "id" : "name"

  # Use provided scope or default to current subscription
  effective_scope = length(var.scope) > 0 ? var.scope : [data.azurerm_subscription.current.id]

  # Create a map of scope names to scope IDs/paths
  # If custom names are provided and match the scope count, use custom names as keys
  # Otherwise, use the basename of each scope as the key
  scope_ids_or_names = length(var.custom_scope_names) == length(local.effective_scope) ? {
    for name in var.custom_scope_names :
    name => local.effective_scope[index(var.custom_scope_names, name)]
    } : {
    for scope in local.effective_scope : basename(scope) => scope
  }

  # When role_definition is a name, we need to resolve it per scope.
  # The role_definition_id for PIM requires the full path:
  #   {scope}/providers/Microsoft.Authorization/roleDefinitions/{guid}
  # When a full ID is passed, we use it directly.

  # Generates a flattened list of eligible role assignments by creating a cartesian product
  # of principal IDs and scopes. For each principal ID, creates an assignment entry
  # for every scope (combining both scope IDs and names), resulting in a list where
  # each principal is paired with all available scopes.
  assignments = flatten([for id in var.principal_id : [for name, scope in local.scope_ids_or_names : {
    principal_id = id
    scope        = scope
    scope_name   = name
  }]])
}
