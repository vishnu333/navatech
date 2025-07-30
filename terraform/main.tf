terraform {
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

# Install NGINX Ingress Controller via Helm
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "ClusterIP"
  }
}

# PostgreSQL StatefulSet
resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name = "postgres"
  }

  spec {
    service_name = "postgres-service"
    replicas     = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:15-alpine"

          env {
            name  = "POSTGRES_DB"
            value = "navatech_db"
          }
          env {
            name  = "POSTGRES_USER"
            value = "navatech_user"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = "navatech_password"
          }

          port {
            container_port = 5432
          }

          resources {
            requests = {
              memory = "256Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "500m"
            }
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "postgres-storage"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres_service" {
  metadata {
    name = "postgres-service"
  }

  spec {
    type = "ClusterIP"
    port {
      port        = 5432
      target_port = 5432
    }
    selector = {
      app = "postgres"
    }
  }
}

resource "kubernetes_config_map" "nginx_config" {
  metadata {
    name = "nginx-config"
  }

  data = {
    "nginx.conf" = <<-EOF
      events {
        worker_connections 1024;
      }
      http {
        server {
          listen 80;
          location / {
            root /usr/share/nginx/html;
            index index.html;
          }
          location /health {
            return 200 "healthy\n";
            add_header Content-Type text/plain;
          }
        }
      }
    EOF
  }
}

resource "kubernetes_deployment" "hello_app" {
  metadata {
    name = "hello-app"
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
        app = "hello-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-app"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"

          port {
            container_port = 80
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.nginx_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "hello_service" {
  metadata {
    name = "hello-service"
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 80
      target_port = 80
    }

    selector = {
      app = "hello-app"
    }
  }
}

resource "kubernetes_ingress_v1" "hello_ingress" {
  metadata {
    name = "hello-ingress"
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "localhost"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.hello_service.metadata[0].name
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