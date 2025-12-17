###############################################################################
# ROSA HCP Cluster Module
# Creates Red Hat OpenShift Service on AWS - Hosted Control Plane
###############################################################################

locals {
  account_role_prefix  = "${var.cluster_name}-account"
  operator_role_prefix = "${var.cluster_name}-operator"
}

###############################################################################
# Data Sources
###############################################################################
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "rhcs_versions" "available" {
  search = "enabled='t' and rosa_enabled='t' and channel_group='stable'"
}

data "rhcs_policies" "all_policies" {}

###############################################################################
# OIDC Configuration
###############################################################################
module "oidc_config" {
  source  = "terraform-redhat/rosa-hcp/rhcs//modules/oidc-config-input"
  version = "~> 1.6"

  region = var.aws_region
}

resource "rhcs_rosa_oidc_config" "oidc_config" {
  managed            = true
  secret_arn         = null
  issuer_url         = module.oidc_config.issuer_url
  installer_role_arn = null
}

###############################################################################
# Account IAM Roles
###############################################################################
module "account_iam_roles" {
  source  = "terraform-redhat/rosa-hcp/rhcs//modules/account-iam-resources"
  version = "~> 1.6"

  account_role_prefix = local.account_role_prefix
  path                = "/"
  permissions_boundary = ""
  tags                = var.tags
}

###############################################################################
# Operator IAM Roles
###############################################################################
module "operator_iam_roles" {
  source  = "terraform-redhat/rosa-hcp/rhcs//modules/operator-roles"
  version = "~> 1.6"

  operator_role_prefix = local.operator_role_prefix
  account_role_prefix  = local.account_role_prefix
  path                 = "/"
  oidc_endpoint_url    = rhcs_rosa_oidc_config.oidc_config.oidc_endpoint_url
  tags                 = var.tags

  depends_on = [module.account_iam_roles]
}

###############################################################################
# ROSA HCP Cluster
###############################################################################
resource "rhcs_cluster_rosa_hcp" "cluster" {
  name                         = var.cluster_name
  version                      = var.ocp_version
  channel_group                = "stable"
  cloud_region                 = var.aws_region
  aws_account_id               = data.aws_caller_identity.current.account_id
  aws_billing_account_id       = data.aws_caller_identity.current.account_id
  availability_zones           = var.availability_zones
  properties                   = var.properties
  sts                          = local.sts_roles
  replicas                     = var.replicas
  compute_machine_type         = var.compute_machine_type
  aws_subnet_ids               = var.private_subnet_ids
  machine_cidr                 = var.machine_cidr
  service_cidr                 = var.service_cidr
  pod_cidr                     = var.pod_cidr
  host_prefix                  = var.host_prefix
  private                      = var.private_cluster
  etcd_encryption              = var.etcd_encryption
  disable_waiting_in_destroy   = false
  destroy_timeout              = 60
  upgrade_acknowledgements_for = var.ocp_version

  lifecycle {
    ignore_changes = [availability_zones]
  }

  depends_on = [module.operator_iam_roles]
}

locals {
  sts_roles = {
    role_arn         = module.account_iam_roles.account_roles_arn["Installer"]
    support_role_arn = module.account_iam_roles.account_roles_arn["Support"]
    instance_iam_roles = {
      worker_role_arn = module.account_iam_roles.account_roles_arn["Worker"]
    }
    operator_role_prefix = local.operator_role_prefix
    oidc_config_id       = rhcs_rosa_oidc_config.oidc_config.id
  }
}

###############################################################################
# Wait for Cluster to be Ready
###############################################################################
resource "rhcs_cluster_wait" "wait_for_cluster" {
  cluster = rhcs_cluster_rosa_hcp.cluster.id
  timeout = 60 # minutes
}

###############################################################################
# Cluster Admin User (Optional)
###############################################################################
resource "rhcs_cluster_rosa_hcp_identity_provider" "htpasswd" {
  count = var.create_admin_user ? 1 : 0

  cluster = rhcs_cluster_rosa_hcp.cluster.id
  name    = "htpasswd"
  htpasswd = {
    users = [{
      username = var.admin_username
      password = var.admin_password
    }]
  }

  depends_on = [rhcs_cluster_wait.wait_for_cluster]
}

###############################################################################
# Store Cluster Credentials in AWS Secrets Manager
###############################################################################
resource "aws_secretsmanager_secret" "cluster_credentials" {
  count = var.store_credentials_in_secrets_manager ? 1 : 0

  name        = "${var.cluster_name}/credentials"
  description = "Credentials for ROSA HCP cluster ${var.cluster_name}"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "cluster_credentials" {
  count = var.store_credentials_in_secrets_manager ? 1 : 0

  secret_id = aws_secretsmanager_secret.cluster_credentials[0].id
  secret_string = jsonencode({
    cluster_name    = rhcs_cluster_rosa_hcp.cluster.name
    cluster_id      = rhcs_cluster_rosa_hcp.cluster.id
    api_url         = rhcs_cluster_rosa_hcp.cluster.api_url
    console_url     = rhcs_cluster_rosa_hcp.cluster.console_url
    oidc_config_id  = rhcs_rosa_oidc_config.oidc_config.id
    admin_username  = var.create_admin_user ? var.admin_username : null
  })
}
