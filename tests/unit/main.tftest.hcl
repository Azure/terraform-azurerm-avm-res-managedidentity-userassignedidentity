mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
  override_resource {
    target = azapi_resource.this
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai"
      output = {
        properties = {
          clientId    = "11111111-1111-1111-1111-111111111111"
          principalId = "22222222-2222-2222-2222-222222222222"
          tenantId    = "33333333-3333-3333-3333-333333333333"
        }
      }
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location            = "westeurope"
  name                = "uai-test"
  resource_group_name = "rg"
  enable_telemetry    = false
}

run "defaults" {
  command = plan

  assert {
    condition     = azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
    error_message = "parent_id must be derived from the resource group name."
  }
  assert {
    condition     = length(azapi_resource.lock) == 0 && length(azapi_resource.federated_identity_credentials) == 0 && length(azapi_resource.role_assignments) == 0
    error_message = "Optional resources must not be created by default."
  }
}

run "lock_and_children" {
  command = plan

  variables {
    lock = { kind = "CanNotDelete" }
    federated_identity_credentials = {
      aks = {
        audience = ["api://AzureADTokenExchange"]
        issuer   = "https://issuer.example.com"
        name     = "aks"
        subject  = "system:serviceaccount:default:sa"
      }
    }
    role_assignments = {
      reader = {
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        scope                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
      }
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-CanNotDelete"
    error_message = "Default lock name expected."
  }
  assert {
    condition     = azapi_resource.federated_identity_credentials["aks"].name == "aks"
    error_message = "Federated credential name expected."
  }
  assert {
    condition     = length(azapi_resource.role_assignments) == 1
    error_message = "One role assignment expected."
  }
}
