terraform {
  required_providers {
    kind = {
      source  = "kbst/kind"
      version = "~> 0.0"
    }
  }
}

provider "kind" {}

# Create Kind cluster
resource "kind_cluster" "navatech" {
  name = "navatech-cluster"
  
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    
    node {
      role = "control-plane"
      
      extra_port_mappings {
        container_port = 80
        host_port      = 8080
      }
    }
  }
} 