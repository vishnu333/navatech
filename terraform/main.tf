terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Create namespace
resource "kubernetes_namespace" "navatech_app" {
  metadata {
    name = "navatech-app"
    labels = {
      name = "navatech-app"
    }
  }
}

# Create ConfigMap for nginx configuration
resource "kubernetes_config_map" "nginx_config" {
  metadata {
    name      = "nginx-config"
    namespace = kubernetes_namespace.navatech_app.metadata[0].name
  }

  data = {
    "nginx.conf" = file("${path.module}/../k8s/nginx.conf")
  }

  depends_on = [kubernetes_namespace.navatech_app]
}

# Create ConfigMap for HTML content
resource "kubernetes_config_map" "html_content" {
  metadata {
    name      = "html-content"
    namespace = kubernetes_namespace.navatech_app.metadata[0].name
  }

  data = {
    "index.html" = file("${path.module}/../k8s/index.html")
  }

  depends_on = [kubernetes_namespace.navatech_app]
}

# Create Deployment
resource "kubernetes_deployment" "navatech_app" {
  metadata {
    name      = "navatech-app"
    namespace = kubernetes_namespace.navatech_app.metadata[0].name
    labels = {
      app = "navatech-app"
    }
  }

  spec {
    replicas = 3

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    selector {
      match_labels = {
        app = "navatech-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "navatech-app"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:1.25-alpine"

          port {
            container_port = 80
          }

          resources {
            requests = {
              memory = "512Mi"
              cpu    = "500m"
            }
            limits = {
              memory = "1Gi"
              cpu    = "1000m"
            }
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
          }

          volume_mount {
            name       = "html-content"
            mount_path = "/usr/share/nginx/html"
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 30
            period_seconds       = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.nginx_config.metadata[0].name
          }
        }

        volume {
          name = "html-content"
          config_map {
            name = kubernetes_config_map.html_content.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_config_map.nginx_config, kubernetes_config_map.html_content]
}

# Create Service
resource "kubernetes_service" "navatech_app" {
  metadata {
    name      = "navatech-app-service"
    namespace = kubernetes_namespace.navatech_app.metadata[0].name
    labels = {
      app = "navatech-app"
    }
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
      name        = "http"
    }

    selector = {
      app = "navatech-app"
    }
  }

  depends_on = [kubernetes_deployment.navatech_app]
}

# Create Ingress
resource "kubernetes_ingress_v1" "navatech_app" {
  metadata {
    name      = "navatech-app-ingress"
    namespace = kubernetes_namespace.navatech_app.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "nginx.ingress.kubernetes.io/ssl-redirect"   = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "navatech.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.navatech_app.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.navatech_app]
} 