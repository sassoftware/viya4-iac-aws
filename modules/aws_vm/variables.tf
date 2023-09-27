# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "name" {
  description = "Name to assign the VM"
  type = string
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
  default     = { project_name = "viya401", cost_center = "rnd", environment = "dev" }
}

variable "vm_type" {
  description = "EC2 instance type"
  type        = string
  default = "m5.4xlarge"
}

variable "cloud_init" {
  description = "Cloud init script to execute"
  type        = string
  default = ""
}

variable "vm_admin" {
  description = "OS Admin User for VMs of EC2 instance"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Path to ssh public key"
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "List of security group ids to associate with the EC2 instance"
  type        = list(string)
  default = []
}

variable "create_public_ip" {
  description = "Toggle the creation of a public EIP to be associated with the EC2 instance"
  type        = bool
  default = false
}

variable "data_disk_count" {
  description = "Number of disks to attach to the EC2 instance"
  type        = number
  default = 0
}

variable "data_disk_size" {
  description = "Size of disk to attach to the EC2 instance in GiBs"
  type        = number
  default = 128
}

variable "data_disk_type" {
  description = "The type of EBS volume for the data disk"
  type        = string
  default = "gp2"
}

variable "data_disk_availability_zone" {
  description = "The AZ where the EBS volume will exist"
  type        = string
  default = ""
}

variable "data_disk_iops" {
  description = "The amount of IOPS to provision for the data disk"
  type        = number
  default = 0
}

variable "os_disk_size" {
  description = "The size of the OS disk"
  type        = number
  default = 64
}

variable "os_disk_type" {
  description = "The type of EBS volume for the OS disk"
  type        = string
  default = "standard"
}

variable "os_disk_delete_on_termination" {
  description = "Delete disk on termination"
  type        = bool
  default = true
}

variable "os_disk_iops" {
  description = "The amount of IOPS to provision for the OS disk"
  type        = number
  default = 0
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in."
  type = string
}

variable "enable_ebs_encryption" {
  description = "Enable encryption on EBS volumes."
  type        = bool
  default     = false
}
