#!/bin/bash

echo "Deploying with Helm..."

cd helm

echo "Installing navatech-app..."
helm install navatech-app navatech-app/

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=navatech-app --timeout=300s

echo "Helm deployment complete!"
echo "Access the app at: http://localhost:8080" 