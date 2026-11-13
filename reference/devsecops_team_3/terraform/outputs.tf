output "virtual_machines" {
  description = "Параметри розгорнутих віртуальних машин (ім'я, IP, ID)"
  value = {
    for k, vm in vsphere_virtual_machine.vm : k => {
      name = vm.name
      ip   = vm.default_ip_address != null ? vm.default_ip_address : var.vms[k].ip
      id   = vm.id
    }
  }
}
