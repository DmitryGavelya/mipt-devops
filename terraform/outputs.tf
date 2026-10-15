output "instance_public_ip" {
  description = "Public IP used by the Ansible inventory."
  value       = yandex_compute_instance.main.network_interface[0].nat_ip_address
}

output "network_id" {
  value = yandex_vpc_network.main.id
}

output "security_group_id" {
  value = yandex_vpc_security_group.host.id
}
