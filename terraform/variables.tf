variable "yc_token" {
  description = "Yandex Cloud OAuth/IAM token. Prefer YC_TOKEN environment variable."
  type        = string
  sensitive   = true
  default     = null
}

variable "cloud_id" {
  type        = string
  default     = null
}

variable "folder_id" {
  type        = string
  default     = null
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "image_id" {
  description = "Ubuntu 22.04 LTS image ID in the selected folder."
  type        = string
}

variable "ssh_public_key" {
  description = "Public key installed for the deployer user."
  type        = string
}

variable "ssh_cidr" {
  description = "CIDR allowed to access SSH. Never use 0.0.0.0/0 in production."
  type        = string
}

variable "instance_name" {
  type    = string
  default = "devops-host"
}
