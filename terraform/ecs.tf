# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# CloudWatch Log Group para ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-logs"
  }
}

# Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "${var.project_name}-${var.environment}-container"
    image = "${aws_ecr_repository.app.repository_url}:latest"

    essential = true

    portMappings = [{
      containerPort = var.app_port
      hostPort      = var.app_port
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "NODE_ENV"
        value = var.environment
      },
      {
        name  = "PORT"
        value = tostring(var.app_port)
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:${var.app_port}/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = {
    Name = "${var.project_name}-${var.environment}-task"
  }
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true # Habilitado porque no usamos NAT Gateway
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.project_name}-${var.environment}-container"
    container_port   = var.app_port
  }

  # Grace period para permitir que la aplicación inicie antes de health checks
  health_check_grace_period_seconds = 60

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-service"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# # Auto Scaling Target
# resource "aws_appautoscaling_target" "ecs_target" {
#   count = var.autoscaling_enabled ? 1 : 0
#
#   max_capacity       = var.autoscaling_max_capacity
#   min_capacity       = var.autoscaling_min_capacity
#   resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace  = "ecs"
# }
#
# # Auto Scaling Policy - CPU
# resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
#   count = var.autoscaling_enabled ? 1 : 0
#
#   name               = "${var.project_name}-${var.environment}-cpu-scaling"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
#   service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace
#
#   target_tracking_scaling_policy_configuration {
#     target_value = var.autoscaling_cpu_target
#
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }
#
#     scale_in_cooldown  = 300
#     scale_out_cooldown = 60
#   }
# }
#
# # Auto Scaling Policy - Memory
# resource "aws_appautoscaling_policy" "ecs_policy_memory" {
#   count = var.autoscaling_enabled ? 1 : 0
#
#   name               = "${var.project_name}-${var.environment}-memory-scaling"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
#   service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace
#
#   target_tracking_scaling_policy_configuration {
#     target_value = var.autoscaling_memory_target
#
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageMemoryUtilization"
#     }
#
#     scale_in_cooldown  = 300
#     scale_out_cooldown = 60
#   }
# }
