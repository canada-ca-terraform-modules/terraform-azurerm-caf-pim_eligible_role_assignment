output "pim_eligible_role_assignments" {
  description = "Outputs the map of all PIM eligible role assignment objects"
  value       = azurerm_pim_eligible_role_assignment.this
  sensitive   = true
}
