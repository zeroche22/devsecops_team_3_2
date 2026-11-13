# DevSecOps — варіант 3

Інфраструктура на VMware vSphere з Oracle Linux 9, Kubernetes і вебзастосунком зі сторінкою авторизації.

Виділений діапазон IP: `192.168.5.120–125`. Назва шаблону Oracle Linux 9 поки невідома; перед розгортанням потрібно знайти або підготувати відповідний шаблон.

[Вихідні конфігурації Terraform, Ansible та GitHub Actions](reference/devsecops_team_3/SOURCE.md).

Поточний етап: дві VM Oracle Linux 9 через Terraform, Zabbix через Ansible, GitHub Actions runner на VM `.120` та CI/CD. Kubernetes, застосунок, Loki/Grafana/Prometheus і backup відкладено.

| VM | IP | Ресурси |
|---|---|---|
| Управління, runner, Ansible, Terraform | `192.168.5.120` | 2 vCPU, 2 ГБ RAM |
| Zabbix server, web, PostgreSQL, agent | `192.168.5.122` | 2 vCPU, 2 ГБ RAM |

Конфігурації підготовлено й перевірено локально. VM у vSphere ще не створено: поточний обліковий запис має роль `Student-ReadOnly`, а шаблон Oracle Linux 9 не підтверджено. Runner у GitHub ще не зареєстровано.

- [Інструкція розгортання](docs/deployment.md).
- [Перевірка доступу до vSphere](docs/vsphere-access.md).
- [Результати локальних перевірок](docs/validation.md).

Робочі конфігурації містяться в `terraform/`, `ansible/`, `.github/workflows/`. Початкову копію попереднього проєкту збережено в `reference/` для порівняння.

Кожен модуль розробляємо в окремій гілці `module-NN-name`. Після завершення перевірок створюємо коміт, виконуємо push і відкриваємо PR до `main`. Наступний залежний модуль починаємо з оновленої `main`; якщо злиття ще не відбулося, зазначаємо залежність гілок у PR.

Поточні залежні гілки конфігурацій: `main` → `module-02-terraform` → `module-03-zabbix` → `module-06-ci-cd`. Публікація коду не означає завершення розгортання.

Цільовий репозиторій: [devsecops_team_3_2](https://github.com/zeroche22/devsecops_team_3_2).
