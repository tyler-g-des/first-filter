resource "kubernetes_namespace" "java_app_namespace" {
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
  metadata {
    name = "java-app-namespace"
  }
}

resource "kubernetes_deployment" "backend-spring" {
  metadata {
    name      = "backend-spring"
    namespace = "java-app-namespace"
  }

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
    namespace = "java-app-namespace"
  }

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