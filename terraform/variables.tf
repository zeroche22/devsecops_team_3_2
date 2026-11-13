variable "vsphere_server" {
  description = "Адреса vCenter."
  type        = string
  default     = "192.168.5.101"
}

variable "vsphere_user" {
  description = "Користувач vCenter."
  type        = string
  default     = "y.manzhos@vsphere.local"
}

variable "vsphere_password" {
  description = "Пароль vCenter; передавати через TF_VAR_vsphere_password або локальний tfvars."
  type        = string
  sensitive   = true
}

variable "vsphere_allow_unverified_ssl" {
  description = "Лише для лабораторії з підтвердженим самопідписаним сертифікатом."
  type        = bool
  default     = false
}

variable "vsphere_datacenter" {
  type    = string
  default = "Datacenter"
}

variable "vsphere_datastore" {
  type    = string
  default = "Toshiba_2TB"
}

variable "vsphere_host" {
  type    = string
  default = "192.168.5.100"
}

variable "vsphere_network" {
  type    = string
  default = "VM Network"
}

variable "vm_folder" {
  type    = string
  default = "Students-VMs/team-3"
}

variable "template_name" {
  description = "Існуючий шаблон Oracle Linux 9 з open-vm-tools та підтримкою guest customization."
  type        = string
  validation {
    condition     = length(trimspace(var.template_name)) > 0
    error_message = "Потрібна підтверджена назва шаблону Oracle Linux 9."
  }
}

variable "ipv4_gateway" {
  description = "Підтверджений шлюз лабораторної мережі."
  type        = string
}

variable "ipv4_netmask" {
  description = "Довжина IPv4 префікса."
  type        = number
  validation {
    condition     = var.ipv4_netmask >= 1 && var.ipv4_netmask <= 30 && floor(var.ipv4_netmask) == var.ipv4_netmask
    error_message = "IPv4 префікс має бути цілим числом від 1 до 30."
  }
}

variable "dns_servers" {
  description = "DNS-сервери лабораторної мережі."
  type        = list(string)
  validation {
    condition     = length(var.dns_servers) > 0
    error_message = "Потрібен щонайменше один DNS-сервер."
  }
}

variable "domain" {
  type    = string
  default = "local.lan"
}

variable "vms" {
  description = "Лише management/runner та Zabbix сьогодні; інші VM поки не створюємо."
  type = map(object({
    name    = string
    ip      = string
    cpus    = number
    memory  = number
    disk_gb = number
  }))
  default = {
    management = {
      name    = "study3-v3-management"
      ip      = "192.168.5.120"
      cpus    = 2
      memory  = 2048
      disk_gb = 30
    }
    zabbix = {
      name    = "study3-v3-zabbix"
      ip      = "192.168.5.122"
      cpus    = 2
      memory  = 2048
      disk_gb = 40
    }
  }
  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      vm.cpus >= 1 && vm.cpus <= 2 && floor(vm.cpus) == vm.cpus &&
      vm.memory >= 512 && vm.memory <= 2048 && floor(vm.memory) == vm.memory &&
      vm.disk_gb >= 20 && floor(vm.disk_gb) == vm.disk_gb
    ])
    error_message = "Ліміти: 1–2 vCPU, 512–2048 MiB RAM; диск — ціле число GiB від 20."
  }
  validation {
    condition = alltrue([
      for vm in values(var.vms) : contains([
        "192.168.5.120", "192.168.5.121", "192.168.5.122",
        "192.168.5.123", "192.168.5.124", "192.168.5.125"
      ], vm.ip)
    ])
    error_message = "Адреси VM повинні належати виділеному діапазону 192.168.5.120–125."
  }
  validation {
    condition = (
      length(distinct([for vm in values(var.vms) : vm.ip])) == length(var.vms) &&
      length(distinct([for vm in values(var.vms) : vm.name])) == length(var.vms)
    )
    error_message = "Імена та IP-адреси VM повинні бути унікальними."
  }
}
