provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks-cluster.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks-cluster.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks-cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks-cluster.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "java_app_namespace" {
  metadata {
    name = "java-app-namespace"
  }
  # depends_on = [azurerm_kubernetes_cluster.aks-cluster]
}

resource "kubernetes_deployment" "db_postgres" {
  metadata {
    name      = "db-postgres"
    namespace = kubernetes_namespace.java_app_namespace.metadata[0].name
  }
  # depends_on = [kubernetes_namespace.java_app_namespace]

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "db-postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "db-postgres"
        }
      }

      spec {
        container {
          name  = "db-postgres"
          image = "postgres" # Reemplaza con la imagen de tu aplicación
          env {
            name = "POSTGRES_DB"
            value = "example"
          }
          env {
            name = "POSTGRES_PASSWORD"
            value = "db-wrz2z"
          }
          port {
            container_port = 5432
            protocol    = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "db_app_service" {
  metadata {
    name      = "db"
    namespace = kubernetes_namespace.java_app_namespace.metadata[0].name
  }

  depends_on = [kubernetes_deployment.db_postgres] 

  spec {
    selector = {
      app = "db-postgres"
    }

    port {
      protocol    = "TCP"
      port        = 5432
      target_port = 5432
    }

    # type="ClusterIP"
  }
}

resource "kubernetes_deployment" "backend_spring" {
  metadata {
    name      = "backend-spring"
    namespace = kubernetes_namespace.java_app_namespace.metadata[0].name
  }
  depends_on = [kubernetes_service.db_app_service]

  spec {
    replicas = 1

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

          env {
            name = "POSTGRES_DB"
            value = "example"
          }

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

  depends_on = [kubernetes_deployment.backend_spring]

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

resource "kubernetes_ingress" "example-ingress" {
  metadata {
    name      = "example-ingress"
    namespace = "java_app_namespace"  # Namespace donde se encuentra tu aplicación
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      host = "ejemplo.com"  # Dominio o subdominio al que se dirigirán las solicitudes

      http {
        path {
          path = "/"
          backend {
            service_name = kubernetes_service.application_app_service.name  # Nombre del servicio al que se dirigirán las solicitudes
            service_port = 8080  # Puerto del servicio
          }
        }
      }
    }
  }
}

