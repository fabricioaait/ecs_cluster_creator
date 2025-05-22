module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"
  cluster_name = "my-ecs-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "test-html-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "web"
    image     = "nginx:alpine"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
    command = [
      "sh",
      "-c",
      "echo '${replace(file("${path.module}/index.html"), "'", "'\\''")}' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"
    ]
    logConfiguration = {
      logDriver = "awslogs",
      options   = {
        "awslogs-group"         = "/ecs/test-html",
        "awslogs-region"        = "us-east-1",
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/test-html"
  retention_in_days = 7
}

resource "aws_ecs_service" "main" {
  name            = "test-html"
  cluster         = module.ecs.cluster_arn
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = module.vpc.public_subnets
    assign_public_ip = true
    security_groups  = [module.vpc.default_security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "web"
    container_port   = 80
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  depends_on = [
    aws_lb_listener.ecs_listener,
    aws_cloudwatch_log_group.ecs_logs
  ]
}