# The identity is the principal in this module, and assignments are made on a consumer-supplied `scope`,
# so the canonical `principal_id` input of the role_assignments interface does not apply.
rule "avm_interface_role_assignments" {
  enabled = false
}
