# Mostrar la ID de la VPC
output "vpc_id" {
  description = "La ID de la VPC creada."
  value       = module.vpc.vpc_id
}

# Mostrar los subnets públicos creados
output "public_subnets" {
  description = "Las subnets públicas creadas."
  value       = module.vpc.public_subnets
}

# Mostrar el ARN del balanceador de carga (ALB)
output "alb_arn" {
  description = "El ARN del Application Load Balancer (ALB)."
  value       = aws_lb.app_lb.arn
}

# Mostrar la URL del balanceador de carga (ALB)
output "alb_dns_name" {
  description = "La URL del Application Load Balancer (ALB)."
  value       = aws_lb.app_lb.dns_name
}

# Mostrar la ID del cluster ECS
output "ecs_cluster_id" {
  description = "La ID del cluster ECS creado."
  value       = aws_ecs_cluster.main.id
}

# Mostrar la URL del repositorio ECR
output "ecr_repository_url" {
  description = "La URL del repositorio ECR."
  value       = aws_ecr_repository.app.repository_url
}

output "image_url" {
  value = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
}