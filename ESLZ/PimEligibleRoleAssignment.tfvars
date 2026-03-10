pim_rbac = [
  {
    # Optional: If omitted, defaults to the current subscription scope. Set the resource scope(s) for the eligible role assignment. Can be management group, subscription, resource group, or resource level.
    # scope = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg1"]
    # custom_scope_names = ["Custom-Name"]      # (Optional) For each scope id above, a custom name within TF for naming the resource. Useful when it doesn't yet exist.
    role         = "Reader"                                 # Can be either the name of the role or full role definition ID
    principal_id = ["00000000-0000-0000-0000-000000000000"] # Must be Object ID of the user, group, or service principal

    # Optional: Justification for the eligible role assignment
    # justification = "Eligible assignment for project operations"

    # Optional: Role assignment condition (ABAC)
    # IMPORTANT: `condition` and `condition_version` must be set together.
    # condition         = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase 'example-container'"
    # condition_version = "2.0"

    # Schedule — controls start time and expiration of the eligibility
    # IMPORTANT: Azure PIM policies often REQUIRE an expiration. If you receive an
    # "ExpirationRule" policy validation error, you must provide a schedule with expiration.
    schedule = {
      # start_date_time = "2026-03-06T00:00:00Z" # Optional: ISO8601 formatted start date/time. Defaults to current time if omitted.
      expiration = {
        duration_days = 30 # Use only one of duration_days, duration_hours, or end_date_time
        # duration_hours = 8
        # end_date_time  = "2027-03-06T00:00:00Z"
      }
    }

    # Optional: Ticket — ticket information for the assignment request
    # ticket = {
    #   number = "INC0012345"
    #   system = "ServiceNow"
    # }
  }
]
