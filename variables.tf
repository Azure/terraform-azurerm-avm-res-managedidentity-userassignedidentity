variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed.  If null, the location will be inferred from the resource group location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the this resource."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{2,127}$", var.name))
    error_message = "The name must start with a letter or number, be between 3 and 128 characters long, and can only contain alphanumerics, hyphens, and underscores."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "federated_identity_credentials" {
  type = map(object({
    audience = list(string)
    issuer   = string
    name     = string
    subject  = string
  }))
  default     = {}
  description = <<-EOT
  A map of federated identity credentials to create on the user assigned identity. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `audience` - (Required) Specifies the audience for this Federated Identity Credential.
  - `issuer` - (Required) Specifies the issuer of this Federated Identity Credential.
  - `name` - (Required) Specifies the name of this Federated Identity Credential. Changing this forces a new resource to be created.
  - `subject` - (Required) Specifies the subject for this Federated Identity Credential.
  EOT
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    authorization_locks                                                     = optional(list(string), [])
    authorization_role_assignments                                          = optional(list(string), [])
    managedidentity_user_assigned_identities                                = optional(list(string), [])
    managedidentity_user_assigned_identities_federated_identity_credentials = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Paths in each resource's `body` whose changes the AzAPI provider ignores. Prefer Terraform's `lifecycle.ignore_changes` when the paths are static; use this variable when the paths must be derived from variables or other non-static values.

Paths use dot notation, for example `properties.isolationScope`. Individual list items cannot be targeted — ignore the whole list property instead. Configuration changes at an ignored path are **not** sent to Azure until that path is removed from the list.

Supplying a non-empty value requires Terraform 1.11 or later, because `ignore_body_changes` is a write-only argument. Changes take effect only after an apply, because the value is held in provider-private state.

- `authorization_locks` - Ignored body paths for the resource lock.
- `authorization_role_assignments` - Ignored body paths for role assignments.
- `managedidentity_user_assigned_identities` - Ignored body paths for the user assigned identity.
- `managedidentity_user_assigned_identities_federated_identity_credentials` - Ignored body paths for federated identity credentials.
DESCRIPTION
  nullable    = false
}

variable "isolation_scope" {
  type        = string
  default     = null
  description = "(Optional) The isolation scope for the user assigned identity. The only possible value is Regional."

  validation {
    condition     = var.isolation_scope == null ? true : var.isolation_scope == "Regional"
    error_message = "The isolation_scope must be null or `Regional`."
  }
}

variable "lock" {
  type = object({
    kind  = string
    name  = optional(string, null)
    notes = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
- `notes` - (Optional) Notes about the lock. This value maps to `Microsoft.Authorization/locks.properties.notes`.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "resource_types" {
  type = object({
    authorization_locks                                                     = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments                                          = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    managedidentity_user_assigned_identities                                = optional(string, "Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30")
    managedidentity_user_assigned_identities_federated_identity_credentials = optional(string, "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module.

- `authorization_locks` - Resource type and API version for the resource lock.
- `authorization_role_assignments` - Resource type and API version for role assignments.
- `managedidentity_user_assigned_identities` - Resource type and API version for the user assigned identity.
- `managedidentity_user_assigned_identities_federated_identity_credentials` - Resource type and API version for federated identity credentials.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every `azapi` resource managed by the module. Defaults to `null` (no custom retry).

- `error_message_regex`  - (Optional) A list of regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.

See <https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#retry> for full semantics.
DESCRIPTION
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    scope                                  = string
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    description                            = optional(string, null)
    principal_type                         = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, null)
  }))
  default     = {}
  description = <<-EOT
  A map of role assignments to create for the user assigned identity. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `scope` - The ID of the scope to assign the role to.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `description` - (Optional) The description of the role assignment.
  - `principal_type` - (Optional) The type of the principal. Possible values are `User`, `Group` and `ServicePrincipal`. Defaults to `ServicePrincipal`.
  - `skip_service_principal_aad_check` - (Optional) No effect when using AzAPI. Retained for backward compatibility.
  EOT
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default per-operation timeouts applied to every `azapi` resource managed by the module. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).

- `create` - (Optional) Timeout for create operations.
- `read`   - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.
- `delete` - (Optional) Timeout for delete operations.
DESCRIPTION
}
