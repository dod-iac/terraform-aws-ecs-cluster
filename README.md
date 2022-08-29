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

By default, the ECS Cluster bootstraps Amazon Linux 2 images.  If using a custom AMI, modify the `image_id` and `user_data` variables as applicable.  If using AWS GovCloud, `ami-b1e0dad0` is equivalent to the default Amazon Linux 2 image in AWS commercial.

Changes to the desired\_capacity, min\_size, and max\_size configuration of the Auto Scaling group are ignored by Terraform.  These parameters can be updated via the AWS Console, API, or CLI.

To connect to an EC2 instance that is part of the ECS cluster, set the subnet\_ids to public subnets and set the key\_name to the name of a key pair.

If you receive a `ECS Service Linked Role does not exist.` error, then you are missing the ECS service Linked Role for your AWS account.  This role only needs to be created once per acocunt, and can be created using the terraform resource shown below.

```hcl
resource "aws_iam_service_linked_role" "ecs" {
  aws_service_name = "ecs.amazonaws.com"
}

## Testing

Run all terratest tests using the `terratest` script.  If using `aws-vault`, you could use `aws-vault exec $AWS_PROFILE -- terratest`.  The `AWS_DEFAULT_REGION` environment variable is required by the tests.  Use `TT_SKIP_DESTROY=1` to not destroy the infrastructure created during the tests.  Use `TT_VERBOSE=1` to log all tests as they are run.  The go test command can be executed directly, too.

## Known Issues

Due to a bug with the terraform provider, manually delete the Autoscaling group when destroying the infrastructure.  See [#5278](https://github.com/hashicorp/terraform-provider-aws/issues/5278).

## Terraform Version

Terraform 0.13. Pin module version to ~> 1.0.0 . Submit pull-requests to main branch.

Terraform 0.11 and 0.12 are not supported.

## License

This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.74.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.74.0, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_ecs_capacity_provider.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |
| [aws_ecs_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_kms_alias.exec_command](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.exec_command](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_launch_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.exec_command](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | Associate a public ip address with an instance in a VPC | `bool` | `false` | no |
| <a name="input_autoscaling_enabled_metrics"></a> [autoscaling\_enabled\_metrics](#input\_autoscaling\_enabled\_metrics) | Metrics enabled by default for the autoscaling group | `list(string)` | <pre>[<br>  "GroupAndWarmPoolDesiredCapacity",<br>  "GroupAndWarmPoolTotalCapacity",<br>  "GroupDesiredCapacity",<br>  "GroupInServiceCapacity",<br>  "GroupInServiceInstances",<br>  "GroupMaxSize",<br>  "GroupMinSize",<br>  "GroupPendingCapacity",<br>  "GroupPendingInstances",<br>  "GroupStandbyCapacity",<br>  "GroupStandbyInstances",<br>  "GroupTerminatingCapacity",<br>  "GroupTerminatingInstances",<br>  "GroupTotalCapacity",<br>  "GroupTotalInstances",<br>  "WarmPoolDesiredCapacity",<br>  "WarmPoolMinSize",<br>  "WarmPoolPendingCapacity",<br>  "WarmPoolTerminatingCapacity",<br>  "WarmPoolTotalCapacity",<br>  "WarmPoolWarmedCapacity"<br>]</pre> | no |
| <a name="input_autoscaling_protect_from_scale_in"></a> [autoscaling\_protect\_from\_scale\_in](#input\_autoscaling\_protect\_from\_scale\_in) | Allows setting instance protection. The Auto Scaling Group will not select instances with this setting for termination during scale in events. | `bool` | `true` | no |
| <a name="input_aws_launch_configuration_name_prefix"></a> [aws\_launch\_configuration\_name\_prefix](#input\_aws\_launch\_configuration\_name\_prefix) | The prefix of the name of the AWS Launch configuration. If not specified, defaults to the value of "name-". | `string` | `""` | no |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | The number of Amazon EC2 instances that should be running in the group. | `number` | `1` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | n/a | `string` | n/a | yes |
| <a name="input_image_id"></a> [image\_id](#input\_image\_id) | The EC2 image ID to launch.  If using AWS GovCloud, "ami-b1e0dad0" is equivalent. | `string` | `"ami-0e999cbd62129e3b1"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | n/a | `string` | `"m5.large"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Name of EC2 key pair used to connect to the instances. | `string` | `""` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | The maximum size of the Auto Scaling Group. | `number` | `1` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | The minimum size of the Auto Scaling Group. | `number` | `1` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the cluster (up to 255 letters, numbers, hyphens, and underscores). | `string` | n/a | yes |
| <a name="input_root_block_device_volume_size"></a> [root\_block\_device\_volume\_size](#input\_root\_block\_device\_volume\_size) | Size of the root block device volume in gibibytes (GiB) used by the EC2 instances in the ECS cluster. | `number` | `32` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | Additional security groups to add to the launch configuration | `list(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The ids of the VPC subnets used by the EC2 instances in the ECS cluster. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to resources part of the ECS Cluster. | `map(string)` | `{}` | no |
| <a name="input_target_capacity"></a> [target\_capacity](#input\_target\_capacity) | The target utilization for the capacity provider. A number between 1 and 100. | `number` | `50` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | The user data provided when launching instances.  If not defined, the userdata.tpl template file is used. | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The id of the VPC used by the EC2 instances in the ECS cluster. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#output\_autoscaling\_group\_arn) | The ARN of the EC2 Auto Scaling group. |
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | The name of the EC2 Auto Scaling group. |
| <a name="output_aws_kms_alias_arn_exec_command"></a> [aws\_kms\_alias\_arn\_exec\_command](#output\_aws\_kms\_alias\_arn\_exec\_command) | The Amazon Resource Name (ARN) of the Execute Command key alias. |
| <a name="output_aws_kms_alias_name_exec_command"></a> [aws\_kms\_alias\_name\_exec\_command](#output\_aws\_kms\_alias\_name\_exec\_command) | The display name of the Execute Command alias. |
| <a name="output_aws_kms_key_arn_exec_command"></a> [aws\_kms\_key\_arn\_exec\_command](#output\_aws\_kms\_key\_arn\_exec\_command) | The Amazon Resource Name (ARN) of the Execute Command key. |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | The Amazon Resource Name (ARN) of the AWS ECS cluster. |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | The name of the AWS ECS cluster. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The id of the AWS Security Group for the AWS ECS cluster. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
