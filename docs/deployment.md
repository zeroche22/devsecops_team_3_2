# Розгортання поточного етапу

Поточний обсяг: дві VM Oracle Linux 9, Zabbix, GitHub Actions runner і CI/CD. Kubernetes, застосунок, Loki/Grafana/Prometheus та backup поки відкладено.

| VM | IP | Ресурси | Призначення |
|---|---|---|---|
| study3-v3-management | 192.168.5.120 | 2 vCPU, 2048 MiB, диск від 30 GiB | Runner, Ansible, Terraform |
| study3-v3-zabbix | 192.168.5.122 | 2 vCPU, 2048 MiB, диск від 40 GiB | Zabbix server/web/PostgreSQL та agent |

Системний диск не зменшується відносно шаблону. Перед apply перевірити вільні адреси, gateway, DNS, datastore і права доступу. Поточне обмеження доступу описано в [звіті](vsphere-access.md).

## Terraform

Потрібні Terraform 1.9.8, доступний vCenter та підготовлений Oracle Linux 9 template з одним системним диском, open-vm-tools, Python, SSH і guest customization. У шаблоні має бути bootstrap-користувач із SSH-ключем і sudo; пароль vCenter не є паролем ОС.

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
chmod 600 terraform/terraform.tfvars
# Заповнити реальні параметри та пароль у локальному файлі або TF_VAR_vsphere_password.
terraform -chdir=terraform init -input=false
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform test
terraform -chdir=terraform plan -out=deployment.tfplan
# Перевірити план: тільки дві нові VM у team-3.
terraform -chdir=terraform apply deployment.tfplan
```

Поточний backend локальний. State, plan і tfvars не комітити; доступ до state має бути обмежений. Apply запускає один оператор з одного місця. До автоматизації apply у CI потрібні спільний backend та блокування; workflow цього етапу самостійно VM не створює і не видаляє.

## Ansible

Потрібен Python 3.12–3.14 для ansible-core 2.20; системний Python 3.15 як controller не підходить. Перевірити доступ по SSH і sudo до обох VM, а fingerprints SSH-ключів — через довірену консоль/джерело. Не вимикати host key checking.

```bash
python3.13 -m venv .ansible-venv
.ansible-venv/bin/pip install -r requirements-ci.txt
.ansible-venv/bin/ansible-galaxy collection install -r ansible/requirements.yml -p .ansible/collections
cp ansible/inventory/hosts.example.yml ansible/inventory/hosts.local.yml
cp ansible/secrets.example.yml ansible/group_vars/all/secrets.local.yml
chmod 600 ansible/group_vars/all/secrets.local.yml
```

Заповнити bootstrap-користувача та шлях до ключа в локальному inventory. У secrets задати незалежні випадкові паролі БД/адміністратора і PSK агента з 64 hex-символів; для PSK можна використати `openssl rand -hex 32`. Цей локальний файл краще зашифрувати через Ansible Vault. PSK у поточному лабораторному варіанті спільний, identity у кожного хоста власний.

```bash
export ANSIBLE_CONFIG="$PWD/ansible/ansible.cfg"
export ANSIBLE_HOME="$PWD/.ansible"
export ANSIBLE_COLLECTIONS_PATH="$PWD/.ansible/collections"
.ansible-venv/bin/ansible-playbook -i ansible/inventory/hosts.local.yml \
  -e @ansible/group_vars/all/secrets.local.yml ansible/playbooks/site.yml
```

Для зашифрованого файла додати `--ask-vault-pass`. Якщо sudo потребує пароля — `--ask-become-pass`. Первинний запуск виконується з робочої машини; runner ще не може налаштовувати сам себе.

Zabbix 7.0.32 і PostgreSQL 16 запускаються через Docker Compose; образи зафіксовано за digest. Ліміти контейнерів: БД 512 MiB, server 512 MiB, web 256 MiB. Це не замінює вимірювання пам'яті всієї VM. Пароль БД читається контейнерами з файла у каталозі root `0700`; сам bind-mounted secret доступний для читання non-root процесам контейнерів. Каталог не робити загальнодоступним.

Плейбук замінює початковий пароль адміністратора, створює групу `Study3 v3` та hosts з шаблоном `Linux by Zabbix agent active`. Агенти працюють як служби Oracle Linux із TLS PSK; пасивний порт слухає лише loopback. Web доступний на `http://192.168.5.122:8080` у лабораторній мережі. Під час роботи з паролями використовувати SSH tunnel або додати TLS перед віддаленим входом у web.

Поточна автоматизація розрахована на початкове створення хостів. Зміна пароля вже ініціалізованого PostgreSQL чи PSK існуючих Zabbix hosts вимагає узгодженої ротації в БД/сервері та агентах; простого редагування secrets недостатньо. Не видаляти volume БД заради зміни пароля.

## Runner і CI/CD

Runner встановлюється на `.120` як служба від окремого користувача `github-runner`. Він не входить до Docker group. Для реєстрації потрібен свіжий короткочасний token з GitHub: Settings → Actions → Runners → New self-hosted runner → Linux/x64. Його передати у локальному secrets як `vault_runner_registration_token`; token не комітити. Повторний запуск runner playbook після закінчення token потребує нового token лише якщо runner ще не зареєстрований.

Публічний SSH-ключ runner додається bootstrap-користувачу обох VM. Для CD цей користувач має мати sudo без запиту пароля або отримувати `ansible_become_password` через secrets. Не запускати недовірені PR на цьому runner.

CI перевіряє Terraform і Ansible на GitHub-hosted runner при push у `main`/`module-*` і PR до `main`. CD запускається вручну тільки з `main`, на runner з label `study3-v3-management`, і застосовує лише Zabbix playbook. Одночасно дозволено один deploy.

У GitHub environment `lab` налаштувати:

- secret `LAB_SECRETS_YAML`: YAML зі значеннями `vault_zabbix_db_password`, `vault_zabbix_admin_password`, `vault_zabbix_agent_psk`, за потреби `ansible_become_password`;
- variable `LAB_KNOWN_HOSTS`: перевірені записи known_hosts для `.120` і `.122`;
- за потреби правила допуску до середовища.

Deploy використовує фіксований inventory з користувачем `devops`; якщо bootstrap-користувач відрізняється, перед увімкненням CD потрібно узгодити цей inventory або створити окремого automation-користувача. Workflow не реєструє runner, не зберігає Terraform state в GitHub artifacts і не робить Terraform apply.

## Перевірка результату

Після розгортання перевірити ОС та ресурси VM у vSphere, повторний Terraform plan, доступ SSH/sudo, стан трьох контейнерів Zabbix, версію API, надходження Latest data з обох hosts і повторний Ansible run. На `.120` перевірити службу runner та стан Online у GitHub. Запустити CI й ручний CD; перевірити health і метрики після повторного застосування. Без цих перевірок розгортання не вважається завершеним.
