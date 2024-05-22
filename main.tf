
resource "azurerm_user_assigned_identity" "this" {
  location            = var.location
  name                = "${local.managed_identity_abrv_prefix}-${var.name}"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_user_assigned_identity.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

