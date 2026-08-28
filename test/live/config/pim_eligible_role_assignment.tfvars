# config/pim_eligible_role_assignment.tfvars
# Minimal, valid fixture exercising the module's common path - a single
# eligible role assignment against a throwaway resource-group scope created
# in the same apply (custom_scope_names, see main.tf) for a single Entra ID
# group principal (test_dependencies.tf), with a 30-day expiration schedule.

role_definition = "Reader"
