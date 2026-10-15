# MIPT DevOps: локальная инфраструктура

Проект настраивает выданную учебную VM: Ansible конфигурирует Ubuntu и Docker,
Terraform управляет локальными Docker-ресурсами, а Docker Compose запускает
простое приложение с reverse proxy.

## Архитектура

Облачные ресурсы студентам не предоставляются, поэтому VM `111.88.162.86`
считается заранее выданным хостом учебного стенда. Terraform запускается
непосредственно на этой VM и создаёт локальный Docker-слой:

- отдельную Docker-сеть;
- Nginx image;
- Docker volume;
- smoke-контейнер на `127.0.0.1:8081`.

Это честная локальная замена облачной части задания: Terraform не создаёт саму
VM, VPC или IAM в облаке, потому что они отсутствуют в предоставленной среде.
Основное Compose-приложение работает отдельно на порту 80.

```text
terraform/                 Docker-инфраструктура и Terraform state
ansible/                   inventory и идемпотентный playbook
compose/                   app + nginx reverse proxy
scripts/monitor.sh         systemd, journal и ошибки syslog
```

## Подготовка хоста Ansible

Команды выполняются локально из корня репозитория:

```bash
ansible-playbook -i ansible/inventory.ini ansible/setup_host.yml -k -K
ansible-playbook -i ansible/inventory.ini ansible/setup_host.yml -k -K
```

Inventory подключается к существующему администратору `student`. Playbook
устанавливает Docker CE и Compose plugin, включает Docker при загрузке,
создаёт `deployer` с passwordless sudo и доступом к Docker, копирует приложение
в `/opt/app` и запускает Compose. Второй запуск должен закончиться с
`changed=0`.

## Terraform на VM

Из-за регионального ограничения Terraform Registry на сервере используется
официальный Docker-образ Terraform и локальный provider mirror. Provider
mirror уже подготовлен на VM в `/tmp/provider-mirror`, а конфигурация CLI — в
`/tmp/terraformrc`.

```bash
ssh student@111.88.162.86
cd ~/mipt-devops/terraform
sudo chown -R student:student .

terraform_vm() {
  sudo docker run --rm \
    -e TF_CLI_CONFIG_FILE=/terraformrc \
    -v "$PWD:/workspace" \
    -v /tmp/provider-mirror:/provider-mirror:ro \
    -v /tmp/terraformrc:/terraformrc:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -w /workspace hashicorp/terraform:1.13.3 "$@"
}

terraform_vm init
terraform_vm validate
terraform_vm plan
terraform_vm apply -auto-approve
terraform_vm state list
```

Ожидаемый state содержит четыре ресурса:

```text
docker_container.infra_smoke
docker_image.nginx
docker_network.infra
docker_volume.nginx_html
```

Повторный `terraform_vm plan` должен показать `No changes`. Порт `8081` привязан
только к loopback, поэтому не конфликтует с reverse proxy Compose на порту 80.
Файл `terraform.tfstate` локально не коммитится.

## Compose и мониторинг

Compose содержит `app` (Nginx со страницей `Hello World`) и внешний `nginx`,
который проксирует запросы по внутренней сети `app-network`.

```bash
cd /opt/app
sudo -u deployer docker compose ps
curl -i -fsS http://127.0.0.1/
sudo /opt/app/monitor.sh docker
```

## Скриншоты для сдачи

В репозитории уже находятся корректные скриншоты:

| Файл | Что подтверждает |
| --- | --- |
| [`img_1.png`](img_1.png) | второй запуск Ansible: `changed=0` |
| [`img.png`](img.png) | `monitor.sh docker`, Docker active и 0 ошибок |
| [`img_2.png`](img_2.png) | `docker compose ps` и HTTP 200 с `Hello World` |

Для полного набора deliverables нужно дополнительно приложить вывод
`terraform state list` и внешний запрос `curl http://111.88.162.86/`. Команды
для пяти итоговых скриншотов:

1. Второй запуск Ansible из корня проекта:

   ```bash
   ansible-playbook -i ansible/inventory.ini ansible/setup_host.yml -k -K
   ```

2. Terraform state на VM (выполняется после объявления функции `terraform_vm`
   из раздела Terraform):

   ```bash
   ssh student@111.88.162.86 'cd ~/mipt-devops/terraform && sudo docker run --rm -e TF_CLI_CONFIG_FILE=/terraformrc -v "$PWD:/workspace" -v /tmp/provider-mirror:/provider-mirror:ro -v /tmp/terraformrc:/terraformrc:ro -v /var/run/docker.sock:/var/run/docker.sock -w /workspace hashicorp/terraform:1.13.3 state list'
   ```

3. Мониторинг Docker:

   ```bash
   ssh student@111.88.162.86 'sudo /opt/app/monitor.sh docker'
   ```

4. Состояние Compose:

   ```bash
   ssh student@111.88.162.86 'cd /opt/app && sudo -u deployer docker compose ps'
   ```

5. Проверка приложения с локального компьютера:

   ```bash
   curl -i -fsS http://111.88.162.86/
   ```

Для пунктов 1–5 нужен отдельный скриншот вывода. Три уже имеющихся изображения
соответствуют пунктам 1, 3 и 4; для пунктов 2 и 5 нужно сделать новые
скриншоты после выполнения команд.

## Git workflow

Работа выполнена в ветке `feature/infra-setup`, затем через Merge Request
влита в `main`. После merge создан тег `v0.1.0`.
