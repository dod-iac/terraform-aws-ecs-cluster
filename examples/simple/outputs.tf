output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.main.name
}

output "ecs_cluster_arn" {
  value = module.ecs_cluster.ecs_cluster_arn
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.ecs_cluster_name
}

output "ecs_task_execution_role_arn" {
  value = module.ecs_task_execution_role.arn
}

output "ecs_task_execution_role_name" {
  value = module.ecs_task_execution_role.name
}

output "ecs_task_role_arn" {
  value = module.ecs_task_role.arn
}

output "ecs_task_role_name" {
  value = module.ecs_task_role.name
}
