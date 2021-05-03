variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable vpc_id {
  description = "Existing vpc id"
  default     = null
}

variable "name" {
  type    = string
  default = null
}

variable "cidr" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "subnets" {
  type        = map
  description = "Map of list of subnet cidr_blocks"
}

variable "existing_subnet_ids" {
  type        = map(list(string))
  default     = {}
  description = "Map subnet usage roles to existing subnet ids"
  # Example:
  # subnet_names = {
  #   'public': 'my_public_subnet', 
  #   'private': 'my_private_subnet', 
  #   'db': 'my_db_subnet'
  # }
}

variable "existing_igw" {
  type = string
  default = null
  description = "Pre-existing VPC Internet Gateway id"
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = false
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}


variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
}

variable "public_subnet_suffix" {
  description = "Suffix to append to public subnets name"
  type        = string
  default     = "public"
}

variable "private_subnet_suffix" {
  description = "Suffix to append to private subnets name"
  type        = string
  default     = "private"
}

variable "database_subnet_suffix" {
  description = "Suffix to append to database subnets name"
  type        = string
  default     = "db"
}

variable "map_public_ip_on_launch" {
  description = "Should be false if you do not want to auto-assign public IP on launch"
  type        = bool
  default     = true
}
