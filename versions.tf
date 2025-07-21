# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# The required_version and required_providers blocks are used to specify the
# Terraform version and provider plugins required to manage the infrastructure
# defined in this configuration. It is important to use specific versions of
# providers to ensure compatibility and prevent breaking changes from affecting
# the infrastructure. The chosen versions are known to be stable and compatible
# with each other.

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4" # Use AWS provider version 5.x
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0" # Use Random provider version 3.x
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0" # Use Local provider version 2.x
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0" # Use Null provider version 3.x
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0" # Use External provider version 2.x
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0" # Use Kubernetes provider version 2.x
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0" # Use TLS provider version 4.x
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.0" # Use CloudInit provider version 2.x
    }
  }
}
