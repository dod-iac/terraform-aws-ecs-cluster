<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Usage

Creates an ECS cluster backed by EC2 instances.

```hcl
module "ecs_instance_role" {
  source = "dod-iac/ecs-instance-role/aws"

  name = format("app-%s-ecs-instance-role-%s", var.application, var.environment)

  tags  = {
    Application = var.application
    Environment = var.environment
    Automation  = "Terraform"
  }
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = module.ecs_instance_role.name
  role = module.ecs_instance_role.name
}

module "ecs_cluster" {
  source = "dod-iac/ecs-cluster/aws"

  iam_instance_profile = aws_iam_instance_profile.ecs_instance_role.arn
  name = format("app-%s-%s", var.application, var.environment)
  subnet_ids = var.subnet_ids
  vpc_id      = var.vpc_id

  tags  = {
    Application = var.application
    Environment = var.environment
    Automation  = "Terraform"
  }
}
```

Changes to the desired\_capacity, min\_size, and max\_size configuration of the Auto Scaling group are ignored by Terraform.  These parameters can be updated via the AWS Console, API, or CLI.

To connect to an EC2 instance that is part of the ECS cluster, set the subnet\_ids to public subnets and set the key\_name to the name of a key pair.

## Testing

Run all terratest tests using the `terratest` script.  If using `aws-vault`, you could use `aws-vault exec $AWS_PROFILE -- terratest`.  The `AWS_DEFAULT_REGION` environment variable is required by the tests.  Use `TT_SKIP_DESTROY=1` to not destroy the infrastructure created during the tests.  The go test command can be executed directly, too.

## Terraform Version

Terraform 0.13. Pin module version to ~> 1.0.0 . Submit pull-requests to master branch.

Terraform 0.11 and 0.12 are not supported.

## License

This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_ecs_capacity_provider.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |
| [aws_ecs_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_launch_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_launch_configuration_name_prefix"></a> [aws\_launch\_configuration\_name\_prefix](#input\_aws\_launch\_configuration\_name\_prefix) | The prefix of the name of the AWS Launch configuration. If not specified, defaults to the value of "name-". | `string` | `""` | no |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | The number of Amazon EC2 instances that should be running in the group. | `number` | `1` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | n/a | `string` | n/a | yes |
| <a name="input_image_id"></a> [image\_id](#input\_image\_id) | n/a | `string` | `"ami-b1e0dad0"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | n/a | `string` | `"m5.large"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Name of EC2 key pair used to connect to the instances. | `string` | `""` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | The maximum size of the Auto Scaling Group. | `number` | `1` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | The minimum size of the Auto Scaling Group. | `number` | `1` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the cluster (up to 255 letters, numbers, hyphens, and underscores). | `string` | n/a | yes |
| <a name="input_root_block_device_volume_size"></a> [root\_block\_device\_volume\_size](#input\_root\_block\_device\_volume\_size) | Size of the root block device volume in gibibytes (GiB) used by the EC2 instances in the ECS cluster. | `number` | `32` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The ids of the VPC subnets used by the EC2 instances in the ECS cluster. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to resources part of the ECS Cluster. | `map(string)` | `{}` | no |
| <a name="input_target_capacity"></a> [target\_capacity](#input\_target\_capacity) | The target utilization for the capacity provider. A number between 1 and 100. | `number` | `50` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The id of the VPC used by the EC2 instances in the ECS cluster. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | The Amazon Resource Name (ARN) of the AWS ECS cluster. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The id of the AWS Security Group for the AWS ECS cluster. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
