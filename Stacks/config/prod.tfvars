###############################################################################
# ROSA HCP Infrastructure - Production Environment Configuration
###############################################################################

#--------------------------------------
# Stack Configuration (User Configurable)
#--------------------------------------
stack_name  = "platform-hcp"      # Change this for different stacks
environment = "prod"

#--------------------------------------
# AWS Region Configuration
#--------------------------------------
aws_region = "us-east-1"           # Change to your preferred region
azs        = ["us-east-1a", "us-east-1b", "us-east-1c"]

#--------------------------------------
# VPC Configuration
#--------------------------------------
vpc_cidr             = "10.200.0.0/16"     # Different CIDR from dev
private_subnet_cidrs = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
public_subnet_cidrs  = ["10.200.101.0/24", "10.200.102.0/24", "10.200.103.0/24"]

#--------------------------------------
# ROSA HCP Cluster Configuration
#--------------------------------------
cluster_name         = ""                  # Leave empty to auto-generate: stack_name-environment
ocp_version          = "4.14"
compute_machine_type = "m5.2xlarge"        # Larger instance for prod
replicas             = 3                   # More replicas for HA
private_cluster      = true                # Private API endpoint

#--------------------------------------
# State Backend Configuration
#--------------------------------------
state_bucket   = "my-terraform-state-bucket"    # CHANGE: Your S3 bucket name
state_key      = "rosa-hcp/prod/terraform.tfstate"
dynamodb_table = "terraform-locks"               # CHANGE: Your DynamoDB table

#--------------------------------------
# GitOps Configuration
#--------------------------------------
git_repo_url = ""                          # CHANGE: Your GitLab repo URL (e.g., https://gitlab.com/org/rosa-hcp.git)
git_branch   = "main"

#--------------------------------------
# Tagging
#--------------------------------------
tags = {
  Project     = "ROSA-HCP"
  Environment = "prod"
  ManagedBy   = "Terraform"
  CostCenter  = "platform-team"
  Criticality = "high"
}
