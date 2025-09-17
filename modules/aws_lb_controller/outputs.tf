output "lb_controller_service_account_name" {
  description = "Name of the AWS Load Balancer Controller service account."
  value       = kubernetes_service_account.lb_controller.metadata[0].name
}

output "lb_controller_iam_role_arn" {
  description = "ARN of the IAM role for the AWS Load Balancer Controller."
  value       = aws_iam_role.lb_controller.arn
}
