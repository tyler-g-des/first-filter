resource "kubernetes_namespace" "example" {
  metadata {
    name = "example-namespace"
  }
}

resource "kubernetes_deployment" "example_app" {
  metadata {
    name      = "backend-spring"
    namespace = kubernetes_namespace.example.metadata[0].name
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

resource "kubernetes_service" "example_app_service" {
  metadata {
    name      = "backend-spring-service"
    namespace = kubernetes_namespace.example.metadata[0].name
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