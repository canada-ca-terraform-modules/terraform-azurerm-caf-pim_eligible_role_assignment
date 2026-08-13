## Usage

```hcl
module "pim_eligible_role_assignment" {
	source = "./"

	scope = [
		"/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example"
	]

	principal_id = [
		"00000000-0000-0000-0000-000000000000"
	]

	role_definition = "Reader"

	pim_eligible_role_assignment = {
		schedule = {
			expiration = {
				duration_days = 30
			}
		}
	}
}
```

## Notes

- `scope` is a `list(string)` of full Azure resource IDs.
- `principal_id` is consumed as a list when generating assignments.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 5.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.11.0, < 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 5.0 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.11.0, < 1.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_pim_eligible_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/pim_eligible_role_assignment) | resource |
| [time_static.start_date_time](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | resource |
| [azurerm_role_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/role_definition) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_scope_names"></a> [custom\_scope\_names](#input\_custom\_scope\_names) | List of names to use instead of the scopes for naming TF resources. This is required if the scope is being created in the same TF invocation. | `list(string)` | `[]` | no |
| <a name="input_pim_eligible_role_assignment"></a> [pim\_eligible\_role\_assignment](#input\_pim\_eligible\_role\_assignment) | Object containing all optional parameters for the PIM eligible role assignment | `any` | `{}` | no |
| <a name="input_principal_id"></a> [principal\_id](#input\_principal\_id) | IDs for the principals (User, Group, Service Principal) to assign the eligible role to | `list(string)` | n/a | yes |
| <a name="input_role_definition"></a> [role\_definition](#input\_role\_definition) | Name or ID of the RBAC role being assigned as PIM eligible | `string` | n/a | yes |
| <a name="input_scope"></a> [scope](#input\_scope) | IDs for the resources where the PIM eligible role will be assigned. Defaults to current subscription if not provided. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pim_eligible_role_assignments"></a> [pim\_eligible\_role\_assignments](#output\_pim\_eligible\_role\_assignments) | Outputs the map of all PIM eligible role assignment objects |
<!-- END_TF_DOCS -->
