variable "aws_launch_configuration_name_prefix" {
  type        = string
  description = "The prefix of the name of the AWS Launch configuration. If not specified, defaults to the value of \"name-\"."
  default     = ""
}

variable "desired_capacity" {
  type        = number
  description = "The number of Amazon EC2 instances that should be running in the group."
  default     = 1
}

variable "name" {
  type        = string
  description = "The name of the cluster (up to 255 letters, numbers, hyphens, and underscores)."
}

variable "iam_instance_profile" {
  type = string
}

variable "image_id" {
  type    = string
  default = "ami-b1e0dad0"
}

variable "instance_type" {
  type    = string
  default = "m5.large"
}

variable "key_name" {
  type        = string
  description = "Name of EC2 key pair used to connect to the instances."
  default     = ""
}

variable "max_size" {
  type        = number
  description = "The maximum size of the Auto Scaling Group."
  default     = 1
}

variable "min_size" {
  type        = number
  description = "The minimum size of the Auto Scaling Group."
  default     = 1
}

variable "root_block_device_volume_size" {
  type        = number
  description = "Size of the root block device volume in gibibytes (GiB) used by the EC2 instances in the ECS cluster."
  default     = 32
}

variable "subnet_ids" {
  type        = list(string)
  description = "The ids of the VPC subnets used by the EC2 instances in the ECS cluster."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources part of the ECS Cluster."
  default     = {}
}

variable "target_capacity" {
  type        = number
  description = "The target utilization for the capacity provider. A number between 1 and 100."
  default     = 50
}

variable "vpc_id" {
  type        = string
  description = "The id of the VPC used by the EC2 instances in the ECS cluster."
}
