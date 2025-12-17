###############################################################################
# ACK IAM Roles Module - Outputs
###############################################################################

output "ack_iam_controller_role_arn" {
  description = "ARN of the IAM role for ACK IAM controller"
  value       = aws_iam_role.ack_iam_controller.arn
}

output "ack_rds_controller_role_arn" {
  description = "ARN of the IAM role for ACK RDS controller"
  value       = aws_iam_role.ack_rds_controller.arn
}

output "ack_iam_controller_policy_arn" {
  description = "ARN of the IAM policy for ACK IAM controller"
  value       = aws_iam_policy.ack_iam_controller.arn
}

output "ack_rds_controller_policy_arn" {
  description = "ARN of the IAM policy for ACK RDS controller"
  value       = aws_iam_policy.ack_rds_controller.arn
}
