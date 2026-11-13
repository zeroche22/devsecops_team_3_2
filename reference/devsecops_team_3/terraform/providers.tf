terraform {
  required_version = ">= 1.0.0"
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "~> 2.4.0"
    }
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.vsphere_allow_unverified_ssl
}