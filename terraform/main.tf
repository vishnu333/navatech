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

# Create Kind cluster using local-exec
resource "null_resource" "kind_cluster" {
  provisioner "local-exec" {
    command = "kind create cluster --name navatech-cluster --config ../kind-config.yaml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kind delete cluster --name navatech-cluster"
  }
} 