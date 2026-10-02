# State migration from the AzureRM implementation (releases prior to the AzAPI migration).
moved {
  from = azurerm_user_assigned_identity.this
  to   = azapi_resource.this
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

moved {
  from = azurerm_federated_identity_credential.this
  to   = azapi_resource.federated_identity_credentials
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}
