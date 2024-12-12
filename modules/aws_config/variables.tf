
variable "conformance_pack_name" {
  type        = string
  description = "NIST Conformance pack name which is supposed to be applied"
}

variable "custom_conformance_pack_name" {
  type        = string
  description = "NIST Conformance pack name which is supposed to be applied"
}

variable "hub_environment" {
  type        = string
  description = "environment for conformance pack"
}

variable "tags" {
  description = "The tags to associate with resources when enable_nist_features is set to true."
  type        = map(string)
  default     = {}
}
