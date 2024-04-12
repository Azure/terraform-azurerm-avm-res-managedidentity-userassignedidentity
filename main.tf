
resource "azurerm_user_assigned_identity" "this" {
  location            = var.location
  name                = "${local.managed_identity_abrv_prefix}-${var.name}"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock.kind != "None" ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_user_assigned_identity.this.id
}
