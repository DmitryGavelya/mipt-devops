output "terraform_network" {
  description = "Docker network created by Terraform on the provided VM."
  value       = docker_network.infra.name
}

output "terraform_container" {
  description = "Nginx smoke container created by Terraform."
  value       = docker_container.infra_smoke.name
}

output "terraform_volume" {
  description = "Docker volume mounted by the Terraform-managed container."
  value       = docker_volume.nginx_html.name
}

output "terraform_smoke_url" {
  description = "Local URL for the Terraform-managed smoke service."
  value       = "http://127.0.0.1:8081"
}
