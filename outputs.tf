output "autoscaling_group_arn" {
  description = "The ARN of the EC2 Auto Scaling group."
  value       = aws_autoscaling_group.main.arn
}

output "autoscaling_group_name" {
  description = "The name of the EC2 Auto Scaling group."
  value       = aws_autoscaling_group.main.name
}

output "ecs_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the AWS ECS cluster."
  value       = aws_ecs_cluster.main.arn
}

output "ecs_cluster_name" {
  description = "The name of the AWS ECS cluster."
  value       = aws_ecs_cluster.main.name
}

output "security_group_id" {
  description = "The id of the AWS Security Group for the AWS ECS cluster."
  value       = aws_security_group.main.id
}

output "aws_kms_alias_arn_exec_command" {
  description = "The Amazon Resource Name (ARN) of the Execute Command key alias."
  value       = aws_kms_alias.exec_command.arn
}

output "aws_kms_alias_name_exec_command" {
  description = "The display name of the Execute Command alias."
  value       = aws_kms_alias.exec_command.name
}

output "aws_kms_key_arn_exec_command" {
  description = "The Amazon Resource Name (ARN) of the Execute Command key."
  value       = aws_kms_key.exec_command.arn
}
