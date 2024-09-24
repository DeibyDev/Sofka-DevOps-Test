provider "aws" {
  region = "us-west-2"
}

# Crear una VPC y subnets públicas
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name = "ecs-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Crear el repositorio de ECR para almacenar la imagen Docker
resource "aws_ecr_repository" "app" {
  name = "my-app-repo"
}

# Crear el cluster ECS
resource "aws_ecs_cluster" "main" {
  name = "ecs-cluster"
}

# Crear el balanceador de carga
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc.default_security_group]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 3000  # Puerto de la aplicación
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_security_group_rule" "allow_http" {
  type            = "ingress"
  from_port       = 3000
  to_port         = 3000
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = module.vpc.default_security_group
}
