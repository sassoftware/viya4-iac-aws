
# For more information on configuring TFlint; see https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/config.md

# For more information on plugins see https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/plugins.md

# For more information on TFlint Ruleset for Terraform; see https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.3.0/docs/rules/README.md

# For more information on TFlint Ruleset for AWS, see https://github.com/terraform-linters/tflint-ruleset-aws/blob/master/docs/rules/README.md

config {
  call_module_type = "none"
}

plugin "aws" {
  enabled = true
  version = "0.37.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Disable rule indicating a false positive
rule "aws_iam_role_policy_attachment_invalid_role" {
  enabled = false
}

plugin "terraform" {
  enabled = true
  preset = "recommended"
}

# Disallow // comments in favor of #.
rule "terraform_comment_syntax" {
  enabled = true
}

# Disallow legacy dot index syntax.
rule "terraform_deprecated_index" {
  enabled = true
}

# Disallow deprecated (0.11-style) interpolation.
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Disallow variable declarations without description.
rule "terraform_documented_variables" {
  enabled = true
}

# Disallow comparisons with [] when checking if a collection is empty.
rule "terraform_empty_list_equality" {
  enabled = true
}

# Disallow specifying a git or mercurial repository as a module source without pinning to a version.
rule "terraform_module_pinned_source" {
  enabled = true
}

# Checks that Terraform modules sourced from a registry specify a version.
rule "terraform_module_version" {
  enabled = true
}

## Enforces naming conventions
rule "terraform_naming_convention" {
  enabled = false
#  custom = "^([a-zA-Z0-9])+([_-][a-zA-Z0-9]+)*$"

}

# Require that all providers have version constraints through required_providers.
rule "terraform_required_providers" {
  enabled = false
}

# Disallow terraform declarations without require_version.
rule "terraform_required_version" {
  enabled = false
}

# Ensure that a module complies with the Terraform Standard Module Structure
rule "terraform_standard_module_structure" {
  enabled = true
}

# Disallow variable declarations without type.
rule "terraform_typed_variables" {
  enabled = true
}

# Disallow variables, data sources, and locals that are declared but never used.
rule "terraform_unused_declarations" {
  enabled = true
}

# Check that all required_providers are used in the module.
rule "terraform_unused_required_providers" {
  enabled = false
}

# terraform.workspace should not be used with a "remote" backend with remote execution.
rule "terraform_workspace_remote" {
  enabled = true
}
