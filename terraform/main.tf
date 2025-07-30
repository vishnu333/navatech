terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
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