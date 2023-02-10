variable "name" {
  type = string
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
  default     = { project_name = "viya401", cost_center = "rnd", environment = "dev" }
}

variable "vm_type" {
  default = "m5.4xlarge"
}

variable "cloud_init" {
  default = ""
}

variable "postgres_administrator_login" {
  description = "The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created."
  default     = "pgadmin"
}

variable "vm_admin" {
  description = "OS Admin User for VMs of AKS Cluster nodes"
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Path to ssh public key"
  default     = ""
}

variable "security_group_ids" {
  default = []
}

variable "create_public_ip" {
  default = false
}

variable "data_disk_count" {
  default = 0
}

variable "data_disk_size" {
  default = 128
}

variable "data_disk_type" {
  default = "gp3"
}

variable "data_disk_availability_zone" {
  default = ""
}

variable "data_disk_iops" {
  default = 0
}

variable "os_disk_size" {
  default = 64
}

variable "os_disk_type" {
  default = "standard"
}

variable "os_disk_delete_on_termination" {
  default = true
}

variable "os_disk_iops" {
  default = 0
}

variable "subnet_id" {
  type = string
}

variable "enable_ebs_encryption" {
  description = "Enable encryption on EBS volumes."
  default     = false
}
