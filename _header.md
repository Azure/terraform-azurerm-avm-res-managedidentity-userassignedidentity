# User-assigned managed identity

Creates a user-assigned managed identity with optional federated identity credentials, a resource lock, and outbound role assignments.

## Breaking input migration

Rename `role_assignments` to `outbound_role_assignments` in module calls. Keep map keys and values unchanged: roles still grant the created identity access at each supplied `scope`, and resource addresses are the AzAPI addresses described by the `moved` blocks. The old input is no longer accepted.

Outbound assignment `description` values are applied to the role assignment.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
> 
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
> 
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.
