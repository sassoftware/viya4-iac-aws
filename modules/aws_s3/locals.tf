locals {
  account_id_map = {
    "us-east-1"         = "127311923021"  # US East (N. Virginia)
    "us-east-2"         = "033677994240"  # US East (Ohio)
    "us-west-1"         = "027434742980"  # US West (N. California)
    "us-west-2"         = "797873946194"  # US West (Oregon)
    "ap-south-1"        = "718504428378"  # Asia Pacific (Mumbai)
    "ap-southeast-1"    = "114774131450"  # Asia Pacific (Singapore)
    "ca-central-1"      = "985666609251"  # Canada (Central)
    "eu-central-1"      = "054676820928"  # Europe (Frankfurt)
    "eu-west-3"         = "009996457667"  # Europe (Paris)
    "eu-west-1"         = "156460612806"  # Europe (Ireland)
    "ap-northeast-1"    = "582318560864"  #Tokyo
  }
    account_id = lookup(local.account_id_map, var.location, null)
}