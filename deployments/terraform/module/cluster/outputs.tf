output "site_url" {
  value = "http://${aws_lb.main_load_balancer.dns_name}/"
}

output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.cluster.arn
}

output "service_name" {
  value = aws_ecs_service.service.name
}

output "service_id" {
  value = aws_ecs_service.service.id
}

output "service_arn" {
  value = aws_ecs_service.service.id
}

output "service_task_execution_role_arn" {
  value = aws_iam_role.task_execution_role.arn
}

output "service_task_role_arn" {
  value = aws_iam_role.task_role.arn
}