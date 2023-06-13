resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      "pod-security.kubernetes.io/warn" = "restricted"
    }
  }
}

resource "helm_release" "argocd_deploy" {
  depends_on = [kubernetes_namespace.argocd]
  name       = "argo-cd"
  chart      = "argo-cd"
  timeout    = 600
  version    = var.chart_version
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  values = [
    templatefile("${path.module}/helm/values/values.yaml", {
      hostname                  = var.argocd_config.hostname
      slack_token               = var.argocd_config.slack_notification_token
      redis_ha_enable           = var.argocd_config.redis_ha_enabled
      autoscaling_enabled       = var.argocd_config.autoscaling_enabled
      enable_argo_notifications = var.argocd_config.argocd_notifications_enabled
    }),
    var.argocd_config.values_yaml
  ]
}

data "kubernetes_secret" "argocd-secret" {
  depends_on = [helm_release.argocd_deploy]
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.namespace
  }
}
