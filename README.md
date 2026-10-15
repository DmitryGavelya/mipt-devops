# MIPT DevOps: локальная инфраструктура

Проект настраивает выданную учебную VM: Ansible конфигурирует Ubuntu и Docker,
Terraform управляет локальным Docker-слоем, а Compose запускает приложение с
reverse proxy.

## Структура

```text
terraform/                 локальная Docker-инфраструктура и state
ansible/                   inventory и идемпотентный playbook
compose/                   app + nginx и конфигурации Nginx
scripts/monitor.sh         systemd, journal и ошибки syslog
```

## Terraform на удалённой VM

Terraform использует Docker provider как локальный эмулятор инфраструктуры:
выданная VM является хостом, а Terraform создаёт отдельную сеть, Nginx-образ и
smoke-контейнер. Это не заменяет саму VM, которая предоставлена учебным
стендом.

```bash
cd ~/mipt-devops/terraform
terraform init
terraform validate
terraform plan
terraform apply
terraform state list
curl http://127.0.0.1:8081
```

Порт `8081` привязан только к loopback и не конфликтует с основным Compose
reverse proxy на порту 80. `terraform.tfstate` не коммитится.

## Ansible

На локальном компьютере из корня проекта:

```bash
ansible-playbook -i ansible/inventory.ini ansible/setup_host.yml -k -K
ansible-playbook -i ansible/inventory.ini ansible/setup_host.yml -k -K
```

Inventory подключается к существующему администратору `student`. Playbook
создаёт `deployer` с passwordless sudo, добавляет его в группу `docker`,
устанавливает Docker CE и Compose plugin, включает Docker при загрузке,
копирует файлы в `/opt/app` и запускает Compose от имени `deployer`.
Второй запуск должен завершиться с `changed=0`.

## Compose и мониторинг

```bash
ssh student@111.88.162.86
cd /opt/app
sudo -u deployer docker compose ps
curl -i -fsS http://127.0.0.1/
sudo /opt/app/monitor.sh docker
```

Compose содержит `app` (Nginx со страницей `Hello World`) и внешний `nginx`,
который проксирует запросы по внутренней сети `app-network`.

## Проверка и отчёт

Для отчёта приложены скриншоты команд Ansible, Terraform state, мониторинга,
Compose и HTTP-проверки. Terraform state создаётся только после реального
`terraform apply` на учебной VM.
