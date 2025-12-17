###############################################################################
# ACK IAM Roles Module - Variables
###############################################################################

variable "cluster_name" {
  description = "Name of the ROSA HCP cluster"
  type        = string
}

variable "oidc_endpoint_url" {
  description = "OIDC endpoint URL for the cluster"
  type        = string
}

variable "ack_namespace" {
  description = "Kubernetes namespace where ACK controllers are deployed"
  type        = string
  default     = "ack-system"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
