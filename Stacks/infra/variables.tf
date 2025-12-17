###############################################################################
# ROSA HCP Infrastructure - Variables
###############################################################################

#--------------------------------------
# Stack Configuration
#--------------------------------------
variable "stack_name" {
  description = "Name of the stack (used for naming resources)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

#--------------------------------------
# AWS Configuration
#--------------------------------------
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

#--------------------------------------
# VPC Configuration
#--------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

#--------------------------------------
# ROSA HCP Cluster Configuration
#--------------------------------------
variable "cluster_name" {
  description = "Name of the ROSA HCP cluster (optional, defaults to stack_name-environment)"
  type        = string
  default     = ""
}

variable "ocp_version" {
  description = "OpenShift version for the cluster"
  type        = string
  default     = "4.14"
}

variable "compute_machine_type" {
  description = "EC2 instance type for compute nodes"
  type        = string
  default     = "m5.xlarge"
}

variable "replicas" {
  description = "Number of compute node replicas"
  type        = number
  default     = 2
  validation {
    condition     = var.replicas >= 2
    error_message = "Minimum 2 replicas required for HA."
  }
}

variable "private_cluster" {
  description = "Whether to create a private cluster (API only accessible within VPC)"
  type        = bool
  default     = true
}

#--------------------------------------
# State Backend Configuration
#--------------------------------------
variable "state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

variable "state_key" {
  description = "S3 key for Terraform state file"
  type        = string
}

variable "dynamodb_table" {
  description = "DynamoDB table for state locking"
  type        = string
}

#--------------------------------------
# GitOps Configuration
#--------------------------------------
variable "git_repo_url" {
  description = "Git repository URL for ArgoCD applications"
  type        = string
  default     = ""
}

variable "git_branch" {
  description = "Git branch for ArgoCD applications"
  type        = string
  default     = "main"
}

#--------------------------------------
# Tagging
#--------------------------------------
variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
