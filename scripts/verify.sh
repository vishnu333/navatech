#!/bin/bash

echo "=== Kubernetes Assignment Verification ==="
echo

echo "1. Cluster Nodes:"
kubectl get nodes
echo

echo "2. Pods Status:"
kubectl get pods
echo

echo "3. Services:"
kubectl get svc
echo

echo "4. Ingress:"
kubectl get ingress
echo

echo "5. Application Access Test:"
curl -s http://localhost:8080/health
echo

echo "6. Zero-downtime Update Test:"
echo "Current image:"
kubectl get deployment navatech-app -o jsonpath='{.spec.template.spec.containers[0].image}'
echo 