// =================================================================
//
// Work of the U.S. Department of Defense, Defense Digital Service.
// Released as open source under the MIT License.  See LICENSE file.
//
// =================================================================

data "aws_region" "current" {}

resource "aws_eip" "nat" {
  count = 3

  vpc = true

  tags = merge(var.tags, {
    Name = format("nat-%d-%s", count.index + 1, var.test_name)
  })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.78.0"

  name = format("app-vpc-%s", var.test_name)
  cidr = "10.0.0.0/16"

  azs             = formatlist(format("%s%%s", data.aws_region.current.name), ["a", "b", "c"])
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # One NAT Gateway per subnet (default behavior)
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  reuse_nat_ips          = true
  external_nat_ip_ids    = aws_eip.nat.*.id

  # DNS Support
  enable_dns_hostnames = true
  enable_dns_support   = true

  # DHCP
  enable_dhcp_options = true

  # VPC endpoint for KMS
  enable_kms_endpoint              = true
  kms_endpoint_private_dns_enabled = true
  kms_endpoint_security_group_ids  = [aws_security_group.endpoint.id]

  # VPC endpoint for Logs
  enable_logs_endpoint              = true
  logs_endpoint_private_dns_enabled = true
  logs_endpoint_security_group_ids  = [aws_security_group.endpoint.id]

  # VPC endpoint for S3
  enable_s3_endpoint = true

  # VPC Endpoint for ECR API
  enable_ecr_api_endpoint              = true
  ecr_api_endpoint_private_dns_enabled = true
  ecr_api_endpoint_security_group_ids  = [aws_security_group.endpoint.id]

  # VPC Endpoint for ECR Docker
  enable_ecr_dkr_endpoint              = true
  ecr_dkr_endpoint_private_dns_enabled = true
  ecr_dkr_endpoint_security_group_ids  = [aws_security_group.endpoint.id]

  # VPC Endpoint for ECS API
  enable_ecs_endpoint              = true
  ecs_endpoint_private_dns_enabled = true
  ecs_endpoint_security_group_ids  = [aws_security_group.endpoint.id]

  # VPC Endpoint for ECS Agent API
  enable_ecs_agent_endpoint              = true
  ecs_agent_endpoint_private_dns_enabled = true
  ecs_agent_endpoint_security_group_ids  = [aws_security_group.endpoint.id]

  # VPC Endpoint for ECS Telemetry API
  enable_ecs_telemetry_endpoint              = true
  ecs_telemetry_endpoint_private_dns_enabled = true
  ecs_telemetry_endpoint_security_group_ids  = [aws_security_group.endpoint.id]

  tags = var.tags
}

module "ecs_instance_role" {
  source  = "dod-iac/ec2-instance-role/aws"
  version = "1.0.1"

  allow_ecs = true
  name      = format("app-ecs-instance-role-%s", var.test_name)

  tags = var.tags
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = module.ecs_instance_role.name
  role = module.ecs_instance_role.name
}

module "ecs_cluster" {
  source  = "../../"

  desired_capacity = 1
  min_size         = 1
  max_size         = 1

  iam_instance_profile          = aws_iam_instance_profile.ecs_instance_role.arn
  instance_type                 = "t2.small"
  name                          = var.test_name
  root_block_device_volume_size = pow(2, 5) # 32GB
  subnet_ids                    = module.vpc.private_subnets
  target_capacity               = 70
  tags                          = var.tags
  vpc_id                        = module.vpc.vpc_id
}
