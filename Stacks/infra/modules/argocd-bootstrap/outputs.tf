###############################################################################
# ArgoCD Bootstrap Module - Outputs
###############################################################################

output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = local.argocd_namespace
}

output "argocd_server_url" {
  description = "ArgoCD server URL (route)"
  value       = "https://openshift-gitops-server-${local.argocd_namespace}.apps.${var.cluster_name}.${var.cluster_api}"
}

output "argocd_instance_name" {
  description = "Name of the ArgoCD instance"
  value       = "openshift-gitops"
}
