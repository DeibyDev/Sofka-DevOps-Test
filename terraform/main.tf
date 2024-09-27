provider "aws" {
  region = var.aws_region
}

# Crear una VPC y subnets públicas
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"  
  name = "ecs-vpc"
  cidr = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_nat_gateway = false  # No necesitamos NAT para subnets públicas
}

# Crear un grupo de seguridad para el balanceador de carga
resource "aws_security_group" "app_lb_sg" {
  name        = "app-lb-sg"
  description = "Grupo de seguridad para el balanceador de carga"
  vpc_id     = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permitir tráfico desde cualquier IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Permitir tráfico hacia cualquier IP
  }
}

# Crear un grupo de seguridad para el servicio ECS
resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service-sg"
  description = "Grupo de seguridad para el servicio ECS"
  vpc_id     = module.vpc.vpc_id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [aws_security_group.app_lb_sg.id]  # Permitir tráfico desde el ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Permitir tráfico hacia cualquier IP
  }
}

# Crear el repositorio de ECR para almacenar la imagen Docker
resource "aws_ecr_repository" "app" {
  name = "my-app-repo"
}

# Crear el cluster ECS
resource "aws_ecs_cluster" "main" {
  name = "ecs-cluster"
}

# Crear el balanceador de carga (Application Load Balancer)
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false  # Esto asegura que sea accesible externamente
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_lb_sg.id]  # Usa el grupo de seguridad creado
  subnets            = module.vpc.public_subnets
}


# Crear el target group para la aplicación
resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 3000  # Puerto donde corre tu aplicación Node.js
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

# Configurar listener para el balanceador de carga
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80  # Puerto en el que el ALB estará expuesto
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Crear una definición de tarea para la aplicación Docker
resource "aws_ecs_task_definition" "app_task_definition" {
  family                   = "app-task"
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn  # Asegúrate de declarar esta variable
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.cpu
  memory                  = var.memory
  
  container_definitions     = jsonencode([{
    name      = "app-container"
    image     = "045695356548.dkr.ecr.us-east-1.amazonaws.com/my-app:latest"
    essential = true
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
  }])
}

# Crear un servicio ECS con Docker
resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.main.id
  desired_count   = 1

  launch_type = "FARGATE"  # Usar ECS con Fargate

  task_definition = aws_ecs_task_definition.app_task_definition.arn

  network_configuration {
    subnets         = module.vpc.public_subnets
    security_groups = [aws_security_group.ecs_service_sg.id]  # Usa el grupo de seguridad creado
    assign_public_ip = true  # Asignar IP pública para que sea accesible
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "app-container"
    container_port   = 3000
  }
}






