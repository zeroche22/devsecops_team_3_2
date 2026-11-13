variable "vsphere_server" {
  type        = string
  description = "IP-адреса або FQDN сервера vSphere / vCenter"
  default     = "192.168.5.101"
}

variable "vsphere_user" {
  type        = string
  description = "Ім'я користувача vSphere"
  default     = "Study3-devops@vsphere.local"
}

variable "vsphere_password" {
  type        = string
  description = "Пароль користувача vSphere"
  sensitive   = true
}

variable "vsphere_allow_unverified_ssl" {
  type        = bool
  description = "Дозволити неперевірені SSL-сертифікати"
  default     = true
}

variable "vsphere_datacenter" {
  type        = string
  description = "Назва цільового датацентру vCenter"
  default     = "Datacenter"
}

variable "vsphere_datastore" {
  type        = string
  description = "Назва цільового сховища (datastore)"
  default     = "Toshiba_2TB"
}

variable "vsphere_host" {
  type        = string
  description = "IP-адреса або FQDN ESXi-хоста"
  default     = "192.168.5.100"
}

variable "vsphere_network" {
  type        = string
  description = "Назва цільової мережі віртуальних машин"
  default     = "VM Network"
}

variable "template_name" {
  type        = string
  description = "Назва шаблону ВМ для клонування"
  default     = "ubuntu_24.04.3"
}

variable "vm_folder" {
  type        = string
  description = "Папка для розміщення ВМ у vCenter"
  default     = "Students-VMs"
}

variable "vms" {
  type = map(object({
    name    = string
    ip      = string
    cpus    = number
    memory  = number
    netmask = number
    gateway = string
    dns     = list(string)
    domain  = string
  }))
  description = "Мапа конфігурацій віртуальних машин (Виділений пул: 192.168.5.102 - 192.168.5.199)"
  default = {
    setup = {
      name    = "Study3-setup"
      ip      = "192.168.5.103"
      cpus    = 2
      memory  = 2048
      netmask = 24
      gateway = "192.168.5.1"
      dns     = ["192.168.5.1", "8.8.8.8"]
      domain  = "local.lan"
    }
    minikube = {
      name    = "Study3-minikube"
      ip      = "192.168.5.104"
      cpus    = 2
      memory  = 2048
      netmask = 24
      gateway = "192.168.5.1"
      dns     = ["192.168.5.1", "8.8.8.8"]
      domain  = "local.lan"
    }
    observability = {
      name    = "Study3-observability"
      ip      = "192.168.5.105"
      cpus    = 2
      memory  = 2048
      netmask = 24
      gateway = "192.168.5.1"
      dns     = ["192.168.5.1", "8.8.8.8"]
      domain  = "local.lan"
    }
  }
}
