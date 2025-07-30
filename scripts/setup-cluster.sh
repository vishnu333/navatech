#!/bin/bash

echo "Setting up Kubernetes cluster..."

if ! command -v kind &> /dev/null; then
    echo "Kind is not installed. Please install it first."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install it first."
    exit 1
fi

if kind get clusters | grep -q "navatech-cluster"; then
    echo "Deleting existing cluster..."
    kind delete cluster --name navatech-cluster
fi

echo "Creating cluster..."
kind create cluster --name navatech-cluster --config kind-config.yaml

echo "Installing nginx ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for ingress to be ready..."
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s

echo "Deploying application..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

echo "Setup complete!"
echo "Access the app at: http://localhost:8080" 