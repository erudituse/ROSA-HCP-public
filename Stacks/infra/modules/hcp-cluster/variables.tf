###############################################################################
# ROSA HCP Cluster Module - Variables
###############################################################################

#--------------------------------------
# Cluster Configuration
#--------------------------------------
variable "cluster_name" {
  description = "Name of the ROSA HCP cluster"
  type        = string
  validation {
    condition     = length(var.cluster_name) <= 54 && can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.cluster_name))
    error_message = "Cluster name must be lowercase alphanumeric, may contain hyphens, and be 54 characters or less."
  }
}

variable "ocp_version" {
  description = "OpenShift version"
  type        = string
  default     = "4.14"
}

variable "aws_region" {
  description = "AWS region for the cluster"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for the cluster"
  type        = list(string)
  default     = []
}

#--------------------------------------
# Network Configuration
#--------------------------------------
variable "vpc_id" {
  description = "VPC ID for the cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes"
  type        = list(string)
}

variable "machine_cidr" {
  description = "CIDR block for machines"
  type        = string
  default     = "10.0.0.0/16"
}

variable "service_cidr" {
  description = "CIDR block for services"
  type        = string
  default     = "172.30.0.0/16"
}

variable "pod_cidr" {
  description = "CIDR block for pods"
  type        = string
  default     = "10.128.0.0/14"
}

variable "host_prefix" {
  description = "Host prefix for pod networking"
  type        = number
  default     = 23
}

variable "private_cluster" {
  description = "Create a private cluster (API only accessible within VPC)"
  type        = bool
  default     = true
}

#--------------------------------------
# Compute Configuration
#--------------------------------------
variable "compute_machine_type" {
  description = "EC2 instance type for compute nodes"
  type        = string
  default     = "m5.xlarge"
}

variable "replicas" {
  description = "Number of compute node replicas"
  type        = number
  default     = 2
}

#--------------------------------------
# Security Configuration
#--------------------------------------
variable "etcd_encryption" {
  description = "Enable etcd encryption"
  type        = bool
  default     = true
}

#--------------------------------------
# Admin User Configuration
#--------------------------------------
variable "create_admin_user" {
  description = "Create an admin user via htpasswd"
  type        = bool
  default     = false
}

variable "admin_username" {
  description = "Admin username"
  type        = string
  default     = "cluster-admin"
}

variable "admin_password" {
  description = "Admin password (should be stored in secrets)"
  type        = string
  default     = ""
  sensitive   = true
}

#--------------------------------------
# Secrets Manager
#--------------------------------------
variable "store_credentials_in_secrets_manager" {
  description = "Store cluster credentials in AWS Secrets Manager"
  type        = bool
  default     = true
}

#--------------------------------------
# Additional Properties
#--------------------------------------
variable "properties" {
  description = "Additional cluster properties"
  type        = map(string)
  default     = {}
}

#--------------------------------------
# Tagging
#--------------------------------------
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
