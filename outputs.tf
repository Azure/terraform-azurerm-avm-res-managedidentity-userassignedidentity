output "client_id" {
  description = "This is the client id for the user assigned identity."
  value       = azapi_resource.this.output.properties.clientId
}

output "principal_id" {
  description = "This is the principal id for the user assigned identity."
  value       = azapi_resource.this.output.properties.principalId
}

output "resource" {
  description = "The object of type User Assigned Identity that was created."
  # Retained for backward compatibility with existing consumers of this output.
  # tflint-ignore: avm_output_entire_resource_disallowed
  value = azapi_resource.this
}

output "resource_id" {
  description = "This is the full output for the resource."
  value       = azapi_resource.this.id
}

output "resource_name" {
  description = "The name of the User Assigned Identity that was created."
  value       = azapi_resource.this.name
}

output "tenant_id" {
  description = "The ID of the Tenant which the Identity belongs to."
  value       = azapi_resource.this.output.properties.tenantId
}
