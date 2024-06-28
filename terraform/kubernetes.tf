provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "java_app_namespace" {
  metadata {
    name = "java-app-namespace"
  }
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

resource "kubernetes_deployment" "backend_spring" {
  metadata {
    name      = "backend-spring"
    namespace = kubernetes_namespace.java_app_namespace.metadata[0].name
  }
  depends_on = [kubernetes_namespace.java_app_namespace]

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "backend-spring"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend-spring"
        }
      }

      spec {
        container {
          name  = "backend-spring"
          image = "tyler0128/spring:391" # Reemplaza con la imagen de tu aplicación
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "application_app_service" {
  metadata {
    name      = "application-service"
    namespace = kubernetes_namespace.java_app_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "backend-spring"
    }

    port {
      protocol    = "TCP"
      port        = 8080
      target_port = 8080
    }

    # type="ClusterIP"
  }
}

