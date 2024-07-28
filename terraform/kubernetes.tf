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

## INGRESS 
# Create public IPs
resource "azurerm_public_ip" "public_ip" {
  name                =  "tylerdesops-publicip"
  location            = azurerm_kubernetes_cluster.aks-cluster.location
  resource_group_name = azurerm_kubernetes_cluster.aks-cluster.node_resource_group
  allocation_method   = "Static"
  sku = "Standard"
  sku_tier = "Regional"
}

#Create DNS
resource "azurerm_dns_zone" "dns" {
  name                = "tylerdesops.com"
  resource_group_name = azurerm_resource_group.aks-resource-group.name
}

resource "azurerm_dns_a_record" "rc" {
  name                = "@"
  zone_name           = azurerm_dns_zone.dns.name
  resource_group_name = azurerm_resource_group.aks-resource-group.name
  ttl                 = 1
  records             = ["${azurerm_public_ip.public_ip.ip_address}"]
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks-cluster.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks-cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks-cluster.kube_config.0.cluster_ca_certificate)
  }
}

# Install Nginx Ingress using Helm Chart
resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  namespace = "ingress-basic"
  create_namespace = true
  chart      = "./charts/ingress-nginx-4.3.0.tgz" #https://github.com/kubernetes/ingress-nginx/releases
  timeout                 = 600
  reuse_values            = true
  recreate_pods           = true
  cleanup_on_fail         = true
  wait                    = true
  verify                  = false
  set {
    name  = "controller.replicaCount"
    value = 1
  }

  set {
    name  = "controller.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name  = "defaultBackend.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = "${azurerm_public_ip.public_ip.ip_address}"
  }
}

resource "kubernetes_ingress" "hello_world_ingress" {
  metadata {
    name = "hello-world-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect"  = "false"
      "nginx.ingress.kubernetes.io/use-regex"      = "true"
      "nginx.ingress.kubernetes.io/rewrite-target"  = "/$2"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        path {
          path = "/hello-world-one(/|$)(.*)"
          path_type = "Prefix"

          backend {
            service {
              name = "aks-helloworld-one"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path = "/hello-world-two(/|$)(.*)"
          path_type = "Prefix"

          backend {
            service {
              name = "aks-helloworld-two"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path = "/(.*)"
          path_type = "Prefix"

          backend {
            service {
              name = "aks-helloworld-one"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress" "hello_world_ingress_static" {
  metadata {
    name        = "hello-world-ingress-static"
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/static/$2"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        path {
          path = "/static(/|$)(.*)"
          path_type = "ImplementationSpecific"  # Cambiado de "Prefix" a "ImplementationSpecific"

          backend {
            service {
              name = "aks-helloworld-one"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}