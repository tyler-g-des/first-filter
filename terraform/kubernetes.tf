resource "kubernetes_namespace" "default" {
  metadata {
    name = "default"
  }
}

resource "kubernetes_deployment" "backend-spring" {
  metadata {
    name      = "backend-spring"
    namespace = kubernetes_namespace.default.metadata[0].name
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

resource "kubernetes_service" "default_app_service" {
  metadata {
    name      = "backend-spring-service"
    namespace = kubernetes_namespace.default.metadata[0].name
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