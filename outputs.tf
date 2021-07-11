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
