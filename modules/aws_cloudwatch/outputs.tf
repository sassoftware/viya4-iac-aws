output "sns_arn" {
  description = "Sns arn o/p"
  value = aws_sns_topic.user_updates.arn
}
