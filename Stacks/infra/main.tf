###############################################################################
# ROSA HCP Infrastructure - Root Module
# Orchestrates VPC, HCP Cluster, and ArgoCD Bootstrap
###############################################################################

locals {
  cluster_name = "${var.stack_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Stack       = var.stack_name
    Environment = var.environment
    Cluster     = local.cluster_name
  })
}

###############################################################################
# VPC Module
###############################################################################
module "vpc" {
  source = "./modules/vpc"

  stack_name           = var.stack_name
  environment          = var.environment
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  single_nat_gateway   = var.environment == "dev" ? true : false
  tags                 = local.common_tags
}

###############################################################################
# ROSA HCP Cluster Module
###############################################################################
module "hcp_cluster" {
  source = "./modules/hcp-cluster"

  depends_on = [module.vpc]

  cluster_name         = var.cluster_name != "" ? var.cluster_name : local.cluster_name
  ocp_version          = var.ocp_version
  aws_region           = var.aws_region
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  compute_machine_type = var.compute_machine_type
  replicas             = var.replicas
  private_cluster      = var.private_cluster
  tags                 = local.common_tags
}

###############################################################################
# ArgoCD Bootstrap Module
###############################################################################
module "argocd_bootstrap" {
  source = "./modules/argocd-bootstrap"

  depends_on = [module.hcp_cluster]

  cluster_name   = module.hcp_cluster.cluster_name
  cluster_api    = module.hcp_cluster.cluster_api_url
  oidc_config_id = module.hcp_cluster.oidc_config_id
  environment    = var.environment
  git_repo_url   = var.git_repo_url
  git_branch     = var.git_branch
  tags           = local.common_tags
}

###############################################################################
# ACK IAM Roles Module
# Creates IAM roles for ACK-IAM and ACK-RDS controllers
###############################################################################
module "ack_iam_roles" {
  source = "./modules/ack-iam-roles"

  depends_on = [module.hcp_cluster]

  cluster_name      = module.hcp_cluster.cluster_name
  oidc_endpoint_url = module.hcp_cluster.oidc_endpoint_url
  ack_namespace     = "ack-system"
  tags              = local.common_tags
}
