#!/bin/bash

set -e

echo "🚀 Setting up Navatech K8s Assignment Environment"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Kind is installed
if ! command -v kind &> /dev/null; then
    print_error "Kind is not installed. Please install it first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install it first."
    exit 1
fi

# Check if cluster already exists
if kind get clusters | grep -q "navatech-cluster"; then
    print_warning "Cluster 'navatech-cluster' already exists. Deleting it..."
    kind delete cluster --name navatech-cluster
fi

print_status "Creating Kind cluster with 3 nodes..."
kind create cluster --name navatech-cluster --config kind-config.yaml

print_status "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

print_status "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

print_status "Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

print_status "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

print_status "Creating ConfigMaps..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/html-configmap.yaml

print_status "Deploying PostgreSQL StatefulSet..."
kubectl apply -f k8s/postgres-statefulset.yaml

print_status "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n navatech-app --timeout=300s

print_status "Deploying application..."
kubectl apply -f k8s/deployment.yaml

print_status "Creating service..."
kubectl apply -f k8s/service.yaml

print_status "Waiting for application pods to be ready..."
kubectl wait --for=condition=ready pod -l app=navatech-app -n navatech-app --timeout=300s

print_status "Creating ingress..."
kubectl apply -f k8s/ingress.yaml

print_status "Waiting for ingress to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=300s

print_success "🎉 Cluster setup completed successfully!"

echo ""
echo "📋 Cluster Information:"
echo "========================"
echo "Cluster Name: navatech-cluster"
echo "Nodes: $(kubectl get nodes --no-headers | wc -l)"
echo "Namespace: navatech-app"
echo ""

echo "🔍 Verification Commands:"
echo "========================"
echo "Check nodes: kubectl get nodes"
echo "Check pods: kubectl get pods -n navatech-app"
echo "Check services: kubectl get svc -n navatech-app"
echo "Check ingress: kubectl get ingress -n navatech-app"
echo ""

echo "🌐 Access Information:"
echo "======================"
echo "Add to /etc/hosts: 127.0.0.1 navatech.local"
echo "Access URL: http://navatech.local"
echo ""

print_status "Setting up port forwarding..."
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80 &
echo "Port forwarding started on localhost:8080"
echo "You can also access via: http://localhost:8080"

print_success "Setup completed! 🚀" 