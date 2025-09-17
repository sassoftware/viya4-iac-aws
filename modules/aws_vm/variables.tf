# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Name to assign to the VM. Used for identification and resource naming.
variable "name" {
  description = "Name to assign the VM"
  type        = string
}

# Map of tags to apply to all VM resources for cost allocation and management. Default includes project, cost center, and environment.
variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
  default     = { project_name = "viya401", cost_center = "rnd", environment = "dev" }
}

# EC2 instance type for the VM (e.g., m6in.xlarge). Determines CPU, memory, and network performance.
variable "vm_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m6in.xlarge"
}

# Cloud-init script to execute on VM startup. Used for initial configuration and automation.
variable "cloud_init" {
  description = "Cloud init script to execute"
  type        = string
  default     = ""
}

# OS admin user for the VM. Default is 'azureuser'.
variable "vm_admin" {
  description = "OS Admin User for VMs of EC2 instance"
  type        = string
  default     = "azureuser"
}

# Path to the SSH public key for VM access. If empty, SSH access may be disabled.
variable "ssh_public_key" {
  description = "Path to ssh public key"
  type        = string
  default     = ""
}

# List of security group IDs to associate with the VM for network access control.
variable "security_group_ids" {
  description = "List of security group ids to associate with the EC2 instance"
  type        = list(string)
  default     = []
}

# If true, creates and associates a public Elastic IP with the VM for external access.
variable "create_public_ip" {
  description = "Toggle the creation of a public EIP to be associated with the EC2 instance"
  type        = bool
  default     = false
}

# Number of data disks to attach to the VM. Used for additional storage.
variable "data_disk_count" {
  description = "Number of disks to attach to the EC2 instance"
  type        = number
  default     = 0
}

# Size in GiB for each data disk attached to the VM.
variable "data_disk_size" {
  description = "Size of disk to attach to the EC2 instance in GiBs"
  type        = number
  default     = 128
}

# EBS volume type for data disks (e.g., gp2, io1).
variable "data_disk_type" {
  description = "The type of EBS volume for the data disk"
  type        = string
  default     = "gp2"
}

# Availability zone for the data disk. Useful for high availability and performance.
variable "data_disk_availability_zone" {
  description = "The AZ where the EBS volume will exist"
  type        = string
  default     = ""
}

# Provisioned IOPS for the data disk. Used for performance-sensitive workloads.
variable "data_disk_iops" {
  description = "The amount of IOPS to provision for the data disk"
  type        = number
  default     = 0
}

# Size in GiB for the OS disk. Default is 64.
variable "os_disk_size" {
  description = "The size of the OS disk"
  type        = number
  default     = 64
}

# EBS volume type for the OS disk (e.g., standard, gp2).
variable "os_disk_type" {
  description = "The type of EBS volume for the OS disk"
  type        = string
  default     = "standard"
}

# If true, deletes the OS disk when the VM is terminated.
variable "os_disk_delete_on_termination" {
  description = "Delete disk on termination"
  type        = bool
  default     = true
}

# Provisioned IOPS for the OS disk. Used for performance-sensitive workloads.
variable "os_disk_iops" {
  description = "The amount of IOPS to provision for the OS disk"
  type        = number
  default     = 0
}

# VPC subnet ID where the VM will be launched.
variable "subnet_id" {
  description = "The VPC Subnet ID to launch in."
  type        = string
}

# If true, enables encryption on all EBS volumes attached to the VM.
variable "enable_ebs_encryption" {
  description = "Enable encryption on EBS volumes."
  type        = bool
  default     = false
}

# If true, enables NIST features under development for compliance and security.
variable "enable_nist_features" {
  description = "A flag to enable NIST features under development for this project"
  type        = bool
  default     = false
}
