variable "docker_host" {
  description = "Docker daemon managed by Terraform on the local VM."
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "instance_name" {
  description = "Prefix used for Terraform-managed local resources."
  type        = string
  default     = "devops-infra"
}

variable "image" {
  description = "Nginx image used by the local infrastructure smoke service."
  type        = string
  default     = "nginx:1.27-alpine"
}
