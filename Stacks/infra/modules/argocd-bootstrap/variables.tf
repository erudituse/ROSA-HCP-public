###############################################################################
# ArgoCD Bootstrap Module - Variables
###############################################################################

variable "cluster_name" {
  description = "Name of the ROSA HCP cluster"
  type        = string
}

variable "cluster_api" {
  description = "API URL of the cluster"
  type        = string
}

variable "oidc_config_id" {
  description = "OIDC configuration ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "gitops_channel" {
  description = "OpenShift GitOps operator channel"
  type        = string
  default     = "latest"
}

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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
