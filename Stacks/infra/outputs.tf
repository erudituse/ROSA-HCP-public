###############################################################################
# ROSA HCP Infrastructure - Outputs
###############################################################################

#--------------------------------------
# VPC Outputs
#--------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT gateways"
  value       = module.vpc.nat_gateway_ips
}

#--------------------------------------
# HCP Cluster Outputs
#--------------------------------------
output "cluster_name" {
  description = "Name of the ROSA HCP cluster"
  value       = module.hcp_cluster.cluster_name
}

output "cluster_id" {
  description = "ID of the ROSA HCP cluster"
  value       = module.hcp_cluster.cluster_id
}

output "cluster_api_url" {
  description = "API URL of the ROSA HCP cluster"
  value       = module.hcp_cluster.cluster_api_url
  sensitive   = true
}

output "cluster_console_url" {
  description = "Console URL of the ROSA HCP cluster"
  value       = module.hcp_cluster.cluster_console_url
}

output "oidc_config_id" {
  description = "OIDC configuration ID for the cluster"
  value       = module.hcp_cluster.oidc_config_id
}

output "cluster_version" {
  description = "OpenShift version of the cluster"
  value       = module.hcp_cluster.cluster_version
}

#--------------------------------------
# ArgoCD Outputs
#--------------------------------------
output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = module.argocd_bootstrap.argocd_server_url
}

output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = module.argocd_bootstrap.argocd_namespace
}

#--------------------------------------
# Connection Information
#--------------------------------------
output "cluster_login_command" {
  description = "Command to login to the cluster"
  value       = "oc login ${module.hcp_cluster.cluster_api_url} --token=<token>"
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig"
  value       = "rosa describe cluster -c ${module.hcp_cluster.cluster_name} -o json | jq -r '.api.url'"
}

#--------------------------------------
# ACK Controller IAM Roles
#--------------------------------------
output "ack_iam_controller_role_arn" {
  description = "IAM role ARN for ACK-IAM controller"
  value       = module.ack_iam_roles.ack_iam_controller_role_arn
}

output "ack_rds_controller_role_arn" {
  description = "IAM role ARN for ACK-RDS controller"
  value       = module.ack_iam_roles.ack_rds_controller_role_arn
}
