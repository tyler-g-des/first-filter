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
          image = "tyler0128/spring:latest"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "aplication_app_service" {
  metadata {
    name      = "backend-spring-service"
    namespace = kubernetes_namespace.java_app_namespace.metadata[0].name
  }
  depends_on = [kubernetes_namespace.java_app_namespace]
  spec {
    selector = {
      app = "backend-spring"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}