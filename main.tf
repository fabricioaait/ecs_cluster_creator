module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  name = "ecs-vpc"
  cidr = "10.0.0.0/16"
  azs            = ["us-east-1a", "us-east-1b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"
  cluster_name = "my-ecs-cluster"
}

resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc.default_security_group_id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "ecs-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

# Add these RIGHT AFTER your ALB listener resource

# 1. IAM Role for ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# 2. Attach the standard ECS policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 3. Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "test-html-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "web"
    image     = "nginxdemos/hello:plain-text"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
    environment = [{
      name  = "RESPONSE"
      value = "<!DOCTYPE html><html><head><title>Fabricio's ECS Cluster</title><style>body{background:#222;color:#fff;font-family:sans-serif;text-align:center;padding-top:10%}h1{font-size:3em;color:#00e676;}p{font-size:1.5em;}</style></head><body><h1>Fabricio's ECS Cluster</h1><p>This page is served from an ECS Fargate container behind an ALB!</p></body></html>"
    }]
  }])
}

# 4. ECS Service
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
}