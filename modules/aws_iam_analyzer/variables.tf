variable "location" {
  type        = string
  description = "Region of deployment"
}

variable "analyzer_type_external" {
  type        = string
  description = "Result of the shell script"
}

variable "analyzer_type_unused" {
  type        = string
  description = "Result of the shell script"
}
variable "tags" {
  description = "The tags to associate with resources when enable_nist_features is set to true."
  type        = map(string)
  default     = {}
}

# variable "analyzer_external" {
#   type        = string
#   default     = "true"
#   description = "Type of the resource"
# }

# variable "existing_analyzer_arn" {
#   description = "ARN value of the analyser"
#   type = string
# }

# variable "analyzer_name" {
#   description = "Name of the analyser"
#   type = string
#   default = "sas-awsng-accessanalyzer-ext-eu-west-3"
# }


