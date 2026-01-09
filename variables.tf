# tflint-ignore-file: role_assignments
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

  - `audiences` - (Required) Specifies the audience for this Federated Identity Credential.
  - `issuer` - (Required) Specifies the issuer of this Federated Identity Credential.
  - `name` - (Required) Specifies the name of this Federated Identity Credential. Changing this forces a new resource to be created.
  - `subject` - (Required) Specifies the subject for this Federated Identity Credential.
  EOT
  nullable    = false
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    scope                                  = string
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, null)
  }))
  default     = {}
  description = <<-EOT
  A map of role assignments to create on the container app environment. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `scope` - The ID of the scope to assign the role to.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Skip validating the Service Principal in AAD before applying the Role Assignment. Defaults to `false`. Changing this forces a new resource to be created.
  EOT
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
