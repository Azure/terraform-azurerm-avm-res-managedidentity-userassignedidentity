
data "azurerm_resource_group" "parent" {
  count = var.location == null ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  resource_group_name = data.azurerm_resource_group.parent[0].name
  location            = coalesce(var.location, local.resource_group_location)
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_user_assigned_identity.this.id
  lock_level = var.lock.kind
}
