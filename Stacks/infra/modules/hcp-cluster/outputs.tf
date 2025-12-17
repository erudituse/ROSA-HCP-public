###############################################################################
# ROSA HCP Cluster Module - Outputs
###############################################################################

output "cluster_id" {
  description = "ID of the ROSA HCP cluster"
  value       = rhcs_cluster_rosa_hcp.cluster.id
}

output "cluster_name" {
  description = "Name of the ROSA HCP cluster"
  value       = rhcs_cluster_rosa_hcp.cluster.name
}

output "cluster_api_url" {
  description = "API URL of the cluster"
  value       = rhcs_cluster_rosa_hcp.cluster.api_url
  sensitive   = true
}

output "cluster_console_url" {
  description = "Console URL of the cluster"
  value       = rhcs_cluster_rosa_hcp.cluster.console_url
}

output "cluster_version" {
  description = "OpenShift version of the cluster"
  value       = rhcs_cluster_rosa_hcp.cluster.current_version
}

output "cluster_state" {
  description = "Current state of the cluster"
  value       = rhcs_cluster_rosa_hcp.cluster.state
}

output "oidc_config_id" {
  description = "OIDC configuration ID"
  value       = rhcs_rosa_oidc_config.oidc_config.id
}

output "oidc_endpoint_url" {
  description = "OIDC endpoint URL"
  value       = rhcs_rosa_oidc_config.oidc_config.oidc_endpoint_url
}

output "account_role_prefix" {
  description = "Prefix used for account IAM roles"
  value       = local.account_role_prefix
}

output "operator_role_prefix" {
  description = "Prefix used for operator IAM roles"
  value       = local.operator_role_prefix
}

output "installer_role_arn" {
  description = "ARN of the installer IAM role"
  value       = module.account_iam_roles.account_roles_arn["Installer"]
}

output "support_role_arn" {
  description = "ARN of the support IAM role"
  value       = module.account_iam_roles.account_roles_arn["Support"]
}

output "worker_role_arn" {
  description = "ARN of the worker IAM role"
  value       = module.account_iam_roles.account_roles_arn["Worker"]
}

output "cluster_admin_token" {
  description = "Cluster admin token (for provider configuration)"
  value       = "" # Token must be obtained via ROSA CLI or OAuth
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64 encoded)"
  value       = "" # CA cert must be obtained from cluster
  sensitive   = true
}

output "infra_id" {
  description = "Infrastructure ID of the cluster"
  value       = rhcs_cluster_rosa_hcp.cluster.infra_id
}

output "credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing cluster credentials"
  value       = var.store_credentials_in_secrets_manager ? aws_secretsmanager_secret.cluster_credentials[0].arn : null
}
