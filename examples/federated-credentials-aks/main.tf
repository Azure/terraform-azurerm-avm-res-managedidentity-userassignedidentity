terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azapi" {}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  enable_telemetry = var.enable_telemetry
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# This is required for resource modules
resource "azapi_resource" "resource_group" {
  location               = module.regions.regions[random_integer.region_index.result].name
  name                   = module.naming.resource_group.name_unique
  type                   = "Microsoft.Resources/resourceGroups@2021-04-01"
  response_export_values = []
}

# This is the module call.
module "test" {
  source = "../../"

  location            = azapi_resource.resource_group.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azapi_resource.resource_group.name
  enable_telemetry    = var.enable_telemetry # see variables.tf
  federated_identity_credentials = {
    aks_workload_identity = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = "https://oidc.prod-aks.azure.com/EXAMPLE_TENANT_ID/EXAMPLE_CLUSTER_ID/"
      name     = "aks-workload-identity"
      subject  = "system:serviceaccount:default:workload-identity-sa"
    }
  }
}
