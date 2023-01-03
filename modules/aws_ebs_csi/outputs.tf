output "ebs_csi_account" {
  value = module.iam_assumable_role_with_oidc.iam_role_arn
}
