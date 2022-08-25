

data "aws_region" "current" {}

locals {
  app_port    = 80
  cpu_size    = 256
  memory_size = 512
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.name}-log-group"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "task_definition" {

  family                   = "${var.name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.cpu_size
  memory                   = local.memory_size
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      name        = "application"
      image       = "${var.repository_url}:latest"
      cpu         = local.cpu_size
      memory      = local.memory_size
      networkMode = "awsvpc"
      portMappings = [
        {
          containerPort = local.app_port
          hostPort      = local.app_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-stream-prefix" = var.name
          "awslogs-region"        = data.aws_region.current.name
        }
      }
      environment = []
    }
  ])

}


resource "aws_ecs_service" "service" {

  depends_on = [
    aws_lb_listener.load_balancer_listener,
  ]

  name            = "${var.name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
      aws_security_group.task_security_group.id
    ]
    subnets          = var.public_subnets.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main_load_balancer_target_group.arn
    container_name   = local.app_port
    container_port   = local.app_port
  }

}
