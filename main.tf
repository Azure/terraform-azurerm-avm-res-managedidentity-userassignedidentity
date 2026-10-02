data "azapi_client_config" "current" {}

resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = local.parent_id
  type      = var.resource_types.managedidentity_user_assigned_identities
  body = {
    properties = var.isolation_scope == null ? {} : {
      isolationScope = var.isolation_scope
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.managedidentity_user_assigned_identities) > 0 ? var.ignore_body_changes.managedidentity_user_assigned_identities : null
  response_export_values = [
    "properties.clientId",
    "properties.principalId",
    "properties.tenantId",
  ]
  retry = var.retry
  tags  = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

# required AVM resources interfaces
resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = azapi_resource.this.id
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = var.lock.kind
      notes = coalesce(var.lock.notes, var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources.")
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource" "federated_identity_credentials" {
  for_each = var.federated_identity_credentials

  name      = each.value.name
  parent_id = azapi_resource.this.id
  type      = var.resource_types.managedidentity_user_assigned_identities_federated_identity_credentials
  body = {
    properties = {
      audiences = each.value.audience
      issuer    = each.value.issuer
      subject   = each.value.subject
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.managedidentity_user_assigned_identities_federated_identity_credentials) > 0 ? var.ignore_body_changes.managedidentity_user_assigned_identities_federated_identity_credentials : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

# Resolves role names to role definition IDs at each assignment scope, as AzureRM did implicitly.
data "azapi_resource_list" "role_definitions" {
  for_each = local.role_assignments_by_name

  parent_id = each.value.scope
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

# The role assignment name must be a GUID; a random value avoids unknown-value replacement.
resource "random_uuid" "role_assignment_name" {
  for_each = var.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  name      = random_uuid.role_assignment_name[each.key].result
  parent_id = each.value.scope
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = {
      for k, v in {
        condition                          = each.value.condition
        conditionVersion                   = each.value.condition_version
        delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
        description                        = each.value.description
        principalId                        = azapi_resource.this.output.properties.principalId
        principalType                      = coalesce(each.value.principal_type, "ServicePrincipal")
        roleDefinitionId = contains(keys(local.role_assignments_by_name), each.key) ? try(
          [for r in data.azapi_resource_list.role_definitions[each.key].output.results : r.id if lower(r.role_name) == lower(each.value.role_definition_id_or_name)][0],
          each.value.role_definition_id_or_name
        ) : each.value.role_definition_id_or_name
      } : k => v if v != null
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # Preserves the server-assigned name of role assignments migrated from AzureRM.
  lifecycle {
    ignore_changes = [name]
  }
}
