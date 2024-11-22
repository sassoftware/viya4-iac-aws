variable "spoke_account_id" {
  type        = string
  description = "Account number"
}

variable "location" {
  type        = string
  description = "Region of deployment"
}

variable "analyzer_name" {
  description = "analyzer name"
  type        = string
}

variable "aws_session_token" {
  description = "Session token for temporary credentials."
  type        = string
  default     = ""
}

variable "aws_access_key_id" {
  description = "Static credential key."
  type        = string
  default     = ""
}

variable "aws_secret_access_key" {
  description = "Static credential secret."
  type        = string
  default     = ""
}

