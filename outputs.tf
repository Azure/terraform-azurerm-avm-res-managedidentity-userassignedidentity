output "resource" {
  value       = azurerm_user_assigned_identity.this.id
  description = "This is the full output for the resource."
}

output "entraID" {
  value       = azurerm_user_assigned_identity.this.principal_id
  description = "This is the principal id for the user assigned identity."
}
