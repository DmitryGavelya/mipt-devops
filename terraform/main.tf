resource "yandex_vpc_network" "main" {
  name = "${var.instance_name}-network"
}

resource "yandex_vpc_subnet" "main" {
  name           = "${var.instance_name}-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_security_group" "host" {
  name       = "${var.instance_name}-ssh"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "SSH from the operator network"
    v4_cidr_blocks = [var.ssh_cidr]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP for the reverse proxy"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_iam_service_account" "deployer" {
  name        = "${var.instance_name}-deployer"
  description = "Least-privilege identity for VM administration"
}

resource "yandex_resourcemanager_folder_iam_member" "deployer_compute" {
  folder_id = var.folder_id
  role      = "compute.editor"
  member    = "serviceAccount:${yandex_iam_service_account.deployer.id}"
}

resource "yandex_compute_instance" "main" {
  name        = var.instance_name
  platform_id = "standard-v3"
  zone        = var.zone
  service_account_id = yandex_iam_service_account.deployer.id

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.main.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.host.id]
  }

  metadata = {
    user-data = <<-EOT
      #cloud-config
      users:
        - name: deployer
          groups: [docker]
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          ssh_authorized_keys:
            - ${var.ssh_public_key}
    EOT
  }
}
