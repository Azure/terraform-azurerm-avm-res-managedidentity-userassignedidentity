mock_provider "azapi" {
  alias = "mock"

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  alias = "mock"

  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      client_id    = "00000000-0000-0000-0000-000000000001"
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/identity-tests/providers/Microsoft.ManagedIdentity/userAssignedIdentities/identity-tests"
      principal_id = "00000000-0000-0000-0000-000000000002"
      tenant_id    = "00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  enable_telemetry    = false
  location            = "westeurope"
  name                = "identity-tests"
  resource_group_name = "identity-tests"
}

run "no_roles_by_default" {
  command = apply

  providers = {
    azapi   = azapi.mock
    azurerm = azurerm.mock


  }

  assert {
    condition     = length(azurerm_role_assignment.this) == 0
    error_message = "Omitting outbound_role_assignments must not create any role assignments."
  }
}

run "null_roles_use_empty_default" {
  command = apply

  providers = {
    azapi   = azapi.mock
    azurerm = azurerm.mock


  }

  variables {
    outbound_role_assignments = null
  }

  assert {
    condition     = length(azurerm_role_assignment.this) == 0
    error_message = "An explicit null must retain the non-null empty collection default."
  }
}

run "named_roles_on_distinct_scopes" {
  command = apply

  providers = {
    azapi   = azapi.mock
    azurerm = azurerm.mock


  }

  variables {
    outbound_role_assignments = {
      reader_on_resource_group = {
        role_definition_id_or_name = "Reader"
        scope                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/target-tests"
        description                = "Reader access to the target resource group"
      }
      reader_on_subscription = {
        role_definition_id_or_name = "Reader"
        scope                      = "/subscriptions/00000000-0000-0000-0000-000000000000"
      }
    }
  }

  assert {
    condition     = toset(keys(azurerm_role_assignment.this)) == toset(["reader_on_resource_group", "reader_on_subscription"])
    error_message = "Role assignment instances must retain their caller-supplied map keys."
  }

  assert {
    condition     = alltrue([for assignment in azurerm_role_assignment.this : assignment.principal_id == output.principal_id])
    error_message = "Every outbound role must be assigned to the created identity."
  }

  assert {
    condition     = alltrue([for key, assignment in azurerm_role_assignment.this : assignment.scope == var.outbound_role_assignments[key].scope])
    error_message = "Outbound grants must retain their distinct target scopes, not the identity resource scope."
  }

  assert {
    condition     = alltrue([for assignment in azurerm_role_assignment.this : assignment.role_definition_name == "Reader"])
    error_message = "Role names must continue to select role_definition_name."
  }

  assert {
    condition     = azurerm_role_assignment.this["reader_on_resource_group"].description == "Reader access to the target resource group"
    error_message = "A supplied description must be applied to the outbound role assignment."
  }

  assert {
    condition = (
      var.outbound_role_assignments["reader_on_subscription"].condition == null &&
      var.outbound_role_assignments["reader_on_subscription"].condition_version == null &&
      var.outbound_role_assignments["reader_on_subscription"].delegated_managed_identity_resource_id == null &&
      var.outbound_role_assignments["reader_on_subscription"].description == null &&
      var.outbound_role_assignments["reader_on_subscription"].skip_service_principal_aad_check == null
    )
    error_message = "The renamed input must preserve the existing null defaults for optional attributes."
  }
}

run "role_definition_id_with_conditions" {
  command = apply

  providers = {
    azapi   = azapi.mock
    azurerm = azurerm.mock


  }

  variables {
    outbound_role_assignments = {
      conditional_blob_reader = {
        role_definition_id_or_name             = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000003"
        scope                                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/target-tests/providers/Microsoft.Storage/storageAccounts/targettests"
        condition                              = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'example'"
        condition_version                      = "2.0"
        delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/target-tests/providers/Microsoft.ManagedIdentity/userAssignedIdentities/delegated-tests"
        description                            = "Conditional access to the target storage account"
        skip_service_principal_aad_check       = true
      }
    }
  }

  assert {
    condition     = azurerm_role_assignment.this["conditional_blob_reader"].role_definition_id == var.outbound_role_assignments["conditional_blob_reader"].role_definition_id_or_name
    error_message = "A fully qualified role definition ID must continue to select role_definition_id."
  }

  assert {
    condition = (
      azurerm_role_assignment.this["conditional_blob_reader"].principal_id == output.principal_id &&
      azurerm_role_assignment.this["conditional_blob_reader"].scope == var.outbound_role_assignments["conditional_blob_reader"].scope
    )
    error_message = "An identified role must still grant the created identity access at the supplied scope."
  }

  assert {
    condition = (
      azurerm_role_assignment.this["conditional_blob_reader"].condition == var.outbound_role_assignments["conditional_blob_reader"].condition &&
      azurerm_role_assignment.this["conditional_blob_reader"].condition_version == "2.0" &&
      azurerm_role_assignment.this["conditional_blob_reader"].delegated_managed_identity_resource_id == var.outbound_role_assignments["conditional_blob_reader"].delegated_managed_identity_resource_id &&
      azurerm_role_assignment.this["conditional_blob_reader"].description == var.outbound_role_assignments["conditional_blob_reader"].description &&
      azurerm_role_assignment.this["conditional_blob_reader"].skip_service_principal_aad_check
    )
    error_message = "Conditions, delegation, descriptions and explicit AAD-check opt-out must reach the existing role resource."
  }
}

run "explicit_aad_check_and_case_insensitive_id" {
  command = apply

  providers = {
    azapi   = azapi.mock
    azurerm = azurerm.mock


  }

  variables {
    outbound_role_assignments = {
      mixed_case_role_id = {
        role_definition_id_or_name       = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/ROLEDEFINITIONS/00000000-0000-0000-0000-000000000003"
        scope                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/target-tests"
        skip_service_principal_aad_check = false
      }
    }
  }

  assert {
    condition     = azurerm_role_assignment.this["mixed_case_role_id"].role_definition_id == var.outbound_role_assignments["mixed_case_role_id"].role_definition_id_or_name
    error_message = "Role definition ID detection must remain case-insensitive without rewriting the supplied ID."
  }

  assert {
    condition     = !azurerm_role_assignment.this["mixed_case_role_id"].skip_service_principal_aad_check
    error_message = "An explicit false AAD-check setting must be preserved."
  }
}
