resource "docker_network" "infra" {
  name = "${var.instance_name}-network"
}

resource "docker_image" "nginx" {
  name = var.image
}

resource "docker_volume" "nginx_html" {
  name = "${var.instance_name}-html"
}

resource "docker_container" "infra_smoke" {
  name  = "${var.instance_name}-nginx"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.infra.name
  }

  volumes {
    volume_name    = docker_volume.nginx_html.name
    container_path = "/usr/share/nginx/html"
    read_only      = true
  }

  ports {
    internal = 80
    external = 8081
    ip       = "127.0.0.1"
  }

  restart = "unless-stopped"
}
