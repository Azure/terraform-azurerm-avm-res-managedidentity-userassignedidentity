locals {
  parent_id                          = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  role_assignments_by_name = {
    for k, v in var.role_assignments : k => v
    if !strcontains(lower(v.role_definition_id_or_name), lower(local.role_definition_resource_substring))
  }
}
