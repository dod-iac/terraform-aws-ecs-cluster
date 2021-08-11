/**
 * ## Usage
 *
 * Creates an ECS cluster backed by EC2 instances.
 *
 * ```hcl
 * module "ecs_instance_role" {
 *   source = "dod-iac/ecs-instance-role/aws"
 *
 *   name = format("app-%s-ecs-instance-role-%s", var.application, var.environment)
 *
 *   tags  = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
 *
 * resource "aws_iam_instance_profile" "ecs_instance_role" {
 *   name = module.ecs_instance_role.name
 *   role = module.ecs_instance_role.name
 * }
 *
 * module "ecs_cluster" {
 *   source = "dod-iac/ecs-cluster/aws"
 *
 *   iam_instance_profile = aws_iam_instance_profile.ecs_instance_role.arn
 *   name = format("app-%s-%s", var.application, var.environment)
 *   subnet_ids = var.subnet_ids
 *   vpc_id      = var.vpc_id
 *
 *   tags  = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
 * ```
 *
 * By default, the ECS Cluster bootstraps Amazon Linux 2 images.  If using a custom AMI, modify the `image_id` and `user_data` variables as applicable.  If using AWS GovCloud, `ami-b1e0dad0` is equivalent to the default Amazon Linux 2 image in AWS commercial.
 *
 * Changes to the desired_capacity, min_size, and max_size configuration of the Auto Scaling group are ignored by Terraform.  These parameters can be updated via the AWS Console, API, or CLI.
 *
 * To connect to an EC2 instance that is part of the ECS cluster, set the subnet_ids to public subnets and set the key_name to the name of a key pair.
 *
 * If you receive a `ECS Service Linked Role does not exist.` error, then you are missing the ECS service Linked Role for your AWS account.  This role only needs to be created once per acocunt, and can be created using the terraform resource shown below.
 *
 * ```hcl
 * resource "aws_iam_service_linked_role" "ecs" {
 *   aws_service_name = "ecs.amazonaws.com"
 * }
 *
 * ## Testing
 *
 * Run all terratest tests using the `terratest` script.  If using `aws-vault`, you could use `aws-vault exec $AWS_PROFILE -- terratest`.  The `AWS_DEFAULT_REGION` environment variable is required by the tests.  Use `TT_SKIP_DESTROY=1` to not destroy the infrastructure created during the tests.  Use `TT_VERBOSE=1` to log all tests as they are run.  The go test command can be executed directly, too.
 *
 * ## Known Issues
 *
 * Due to a bug with the terraform provider, manually delete the Autoscaling group when destroying the infrastructure.  See [#5278](https://github.com/hashicorp/terraform-provider-aws/issues/5278).
 *
 * ## Terraform Version
 *
 * Terraform 0.13. Pin module version to ~> 1.0.0 . Submit pull-requests to master branch.
 *
 * Terraform 0.11 and 0.12 are not supported.
 *
 * ## License
 *
 * This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.
 */

data "aws_region" "current" {}

resource "aws_security_group" "main" {
  name        = var.name
  description = format("Security group for ECS cluster %s", var.name)
  vpc_id      = var.vpc_id
  tags        = var.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "main" {
  associate_public_ip_address      = var.associate_public_ip_address
  ebs_optimized                    = false
  iam_instance_profile             = var.iam_instance_profile
  instance_type                    = var.instance_type
  image_id                         = var.image_id
  key_name                         = length(var.key_name) > 0 ? var.key_name : null
  name_prefix                      = length(var.aws_launch_configuration_name_prefix) > 0 ? var.aws_launch_configuration_name_prefix : format("%s-", var.name)
  security_groups                  = concat([aws_security_group.main.id], var.security_groups)
  vpc_classic_link_security_groups = []

  root_block_device {
    volume_type           = "standard"
    volume_size           = var.root_block_device_volume_size
    delete_on_termination = true
    encrypted             = true
    iops                  = 0
  }

  user_data = length(var.user_data) > 0 ? var.user_data : templatefile(format("%s/userdata.tpl", path.module), {
    ecs_cluster = var.name,
    region      = data.aws_region.current.name
    tags        = merge(var.tags, { Name = var.name })
  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  desired_capacity      = var.desired_capacity
  launch_configuration  = aws_launch_configuration.main.id
  max_size              = var.max_size
  min_size              = var.min_size
  name                  = var.name
  protect_from_scale_in = var.autoscaling_protect_from_scale_in
  tags                  = [for k, v in merge(var.tags, { Name = var.name, AmazonECSManaged = "" }) : { "key" : k, "value" : v, "propagate_at_launch" : true }]
  termination_policies  = ["OldestLaunchConfiguration", "Default"]
  vpc_zone_identifier   = var.subnet_ids

  metrics_granularity = "1Minute" // Only valid value
  enabled_metrics     = var.autoscaling_enabled_metrics

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity, max_size, min_size]
  }
}

resource "aws_ecs_capacity_provider" "main" {
  name = var.name
  tags = var.tags

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.main.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = var.target_capacity
    }
  }
}

resource "aws_ecs_cluster" "main" {
  capacity_providers = [aws_ecs_capacity_provider.main.name]
  name               = var.name
  tags               = var.tags

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
    base              = 0
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
