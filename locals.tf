
locals {
  resource_group_location            = try(data.azurerm_resource_group.parent[0].location, null)
}

