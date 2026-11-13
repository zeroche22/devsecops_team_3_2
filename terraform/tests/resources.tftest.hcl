mock_provider "vsphere" {
  mock_data "vsphere_virtual_machine" {
    defaults = {
      guest_id                = "oracleLinux9_64Guest"
      firmware                = "efi"
      scsi_type               = "lsilogic"
      network_interface_types = ["vmxnet3"]
      disks = [{
        size             = 20
        thin_provisioned = true
      }]
    }
  }
}

variables {
  template_name    = "oracle-linux-9-test-template"
  vsphere_password = "mock-provider-only"
  ipv4_gateway     = "192.168.5.1"
  ipv4_netmask     = 24
  dns_servers      = ["192.168.5.1"]
}

run "today_only_management_and_zabbix" {
  command = plan
  assert {
    condition     = length(vsphere_virtual_machine.vm) == 2
    error_message = "Сьогодні створюємо лише management та Zabbix VM."
  }
  assert {
    condition = alltrue([
      for vm in values(vsphere_virtual_machine.vm) : vm.num_cpus <= 2 && vm.memory <= 2048
    ])
    error_message = "VM перевищує погоджені ресурси."
  }
  assert {
    condition = (
      vsphere_virtual_machine.vm["management"].clone[0].customize[0].network_interface[0].ipv4_address == "192.168.5.120" &&
      vsphere_virtual_machine.vm["zabbix"].clone[0].customize[0].network_interface[0].ipv4_address == "192.168.5.122"
    )
    error_message = "Адреси поточного розгортання повинні бути .120 та .122."
  }
}

run "reject_resource_limit_violation" {
  command = plan
  variables {
    vms = {
      invalid = {
        name    = "invalid"
        ip      = "192.168.5.120"
        cpus    = 4
        memory  = 4096
        disk_gb = 30
      }
    }
  }
  expect_failures = [var.vms]
}

run "reject_old_project_address" {
  command = plan
  variables {
    vms = {
      invalid = {
        name    = "invalid"
        ip      = "192.168.5.103"
        cpus    = 2
        memory  = 2048
        disk_gb = 30
      }
    }
  }
  expect_failures = [var.vms]
}
