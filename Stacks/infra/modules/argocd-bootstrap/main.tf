###############################################################################
# ArgoCD Bootstrap Module
# Installs OpenShift GitOps (ArgoCD) via OLM and configures App-of-Apps
###############################################################################

locals {
  argocd_namespace = "openshift-gitops"
}

###############################################################################
# OpenShift GitOps Operator Installation via OLM
###############################################################################

# Create the operator namespace (usually already exists)
resource "kubernetes_namespace" "openshift_gitops_operator" {
  metadata {
    name = "openshift-gitops-operator"
    labels = {
      "openshift.io/cluster-monitoring" = "true"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].labels, metadata[0].annotations]
  }
}

# OperatorGroup for OpenShift GitOps
resource "kubernetes_manifest" "gitops_operator_group" {
  manifest = {
    apiVersion = "operators.coreos.com/v1"
    kind       = "OperatorGroup"
    metadata = {
      name      = "openshift-gitops-operator"
      namespace = kubernetes_namespace.openshift_gitops_operator.metadata[0].name
    }
    spec = {
      upgradeStrategy = "Default"
    }
  }
}

# Subscription for OpenShift GitOps Operator
resource "kubernetes_manifest" "gitops_subscription" {
  manifest = {
    apiVersion = "operators.coreos.com/v1alpha1"
    kind       = "Subscription"
    metadata = {
      name      = "openshift-gitops-operator"
      namespace = kubernetes_namespace.openshift_gitops_operator.metadata[0].name
    }
    spec = {
      channel             = var.gitops_channel
      installPlanApproval = "Automatic"
      name                = "openshift-gitops-operator"
      source              = "redhat-operators"
      sourceNamespace     = "openshift-marketplace"
    }
  }

  depends_on = [kubernetes_manifest.gitops_operator_group]
}

###############################################################################
# Wait for ArgoCD Instance to be Ready
###############################################################################
resource "time_sleep" "wait_for_gitops_operator" {
  depends_on      = [kubernetes_manifest.gitops_subscription]
  create_duration = "120s"
}

###############################################################################
# Configure ArgoCD Instance
###############################################################################
resource "kubernetes_manifest" "argocd_instance" {
  manifest = {
    apiVersion = "argoproj.io/v1beta1"
    kind       = "ArgoCD"
    metadata = {
      name      = "openshift-gitops"
      namespace = local.argocd_namespace
    }
    spec = {
      server = {
        autoscale = {
          enabled = false
        }
        grpc = {
          ingress = {
            enabled = false
          }
        }
        ingress = {
          enabled = false
        }
        resources = {
          limits = {
            cpu    = "500m"
            memory = "256Mi"
          }
          requests = {
            cpu    = "125m"
            memory = "128Mi"
          }
        }
        route = {
          enabled = true
          tls = {
            termination = "reencrypt"
          }
        }
        service = {
          type = "ClusterIP"
        }
      }
      applicationSet = {
        resources = {
          limits = {
            cpu    = "2"
            memory = "1Gi"
          }
          requests = {
            cpu    = "250m"
            memory = "512Mi"
          }
        }
      }
      controller = {
        processors = {}
        resources = {
          limits = {
            cpu    = "2"
            memory = "2Gi"
          }
          requests = {
            cpu    = "250m"
            memory = "1Gi"
          }
        }
        sharding = {}
      }
      grafana = {
        enabled = false
      }
      ha = {
        enabled = false
      }
      prometheus = {
        enabled = false
      }
      redis = {
        resources = {
          limits = {
            cpu    = "500m"
            memory = "256Mi"
          }
          requests = {
            cpu    = "250m"
            memory = "128Mi"
          }
        }
      }
      repo = {
        resources = {
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
          requests = {
            cpu    = "250m"
            memory = "256Mi"
          }
        }
      }
      resourceExclusions = <<-EOF
        - apiGroups:
          - tekton.dev
          clusters:
          - '*'
          kinds:
          - TaskRun
          - PipelineRun
      EOF
      sso = {
        dex = {
          openShiftOAuth = true
          resources = {
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "128Mi"
            }
          }
        }
        provider = "dex"
      }
      rbac = {
        defaultPolicy = ""
        policy        = <<-EOF
          g, system:cluster-admins, role:admin
          g, cluster-admins, role:admin
        EOF
        scopes        = "[groups]"
      }
    }
  }

  depends_on = [time_sleep.wait_for_gitops_operator]
}

###############################################################################
# Wait for ArgoCD to be Ready
###############################################################################
resource "time_sleep" "wait_for_argocd" {
  depends_on      = [kubernetes_manifest.argocd_instance]
  create_duration = "60s"
}

###############################################################################
# App-of-Apps: Platform Applications
###############################################################################
resource "kubernetes_manifest" "platform_app_of_apps" {
  count = var.git_repo_url != "" ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "platform-apps"
      namespace = local.argocd_namespace
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = var.git_branch
        path           = "Stacks/app/argocd/applicationsets"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = local.argocd_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [time_sleep.wait_for_argocd]
}

###############################################################################
# Grant ArgoCD cluster-admin permissions
###############################################################################
resource "kubernetes_cluster_role_binding" "argocd_cluster_admin" {
  metadata {
    name = "argocd-application-controller-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "openshift-gitops-argocd-application-controller"
    namespace = local.argocd_namespace
  }

  depends_on = [time_sleep.wait_for_argocd]
}
