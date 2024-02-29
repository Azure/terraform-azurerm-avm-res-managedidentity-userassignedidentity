output "entra_id" {
  description = "This is the principal id for the user assigned identity."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "resource" {
  description = "This is the full output for the resource."
  value       = azurerm_user_assigned_identity.this.id
}

output "resource_name" {
  description = "The name of the User Assigned Identity that was created"
  value       = azurerm_user_assigned_identity.this.name
}

output "resource_object" {
  description = "The object of type User Assigned Identity that was created"
  value       = azurerm_user_assigned_identity.this
}
