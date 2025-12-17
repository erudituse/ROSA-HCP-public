###############################################################################
# ROSA HCP Infrastructure - Provider Configuration
###############################################################################

terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    rhcs = {
      source  = "terraform-redhat/rhcs"
      version = "~> 1.6"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

###############################################################################
# AWS Provider
###############################################################################
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

###############################################################################
# Red Hat Cloud Services (RHCS) Provider
# Used for ROSA HCP cluster management
###############################################################################
provider "rhcs" {
  # Token is read from RHCS_TOKEN environment variable
  # or can be set via: token = var.rhcs_token
}

###############################################################################
# Kubernetes Provider
# Configured after cluster is created
###############################################################################
provider "kubernetes" {
  host                   = try(module.hcp_cluster.cluster_api_url, "")
  cluster_ca_certificate = try(base64decode(module.hcp_cluster.cluster_ca_certificate), "")
  token                  = try(module.hcp_cluster.cluster_admin_token, "")
}

###############################################################################
# Helm Provider
# Used for ArgoCD installation
###############################################################################
provider "helm" {
  kubernetes {
    host                   = try(module.hcp_cluster.cluster_api_url, "")
    cluster_ca_certificate = try(base64decode(module.hcp_cluster.cluster_ca_certificate), "")
    token                  = try(module.hcp_cluster.cluster_admin_token, "")
  }
}
