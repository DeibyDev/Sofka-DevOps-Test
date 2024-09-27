variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "cpu" {
  description = "CPU para el contenedor"
  type        = number
  default     = 2048  # 2 vCPUs
}

variable "memory" {
  description = "Memoria para el contenedor (MiB)"
  type        = number
  default     = 4096  # 4 GiB
}

variable "image_tag" {
  default = "latest"
}