#!/bin/bash

echo "Setting up with Terraform..."

cd terraform

echo "Checking if Kind is installed..."
if ! command -v kind &> /dev/null; then
    echo "Kind is not installed. Please install it first."
    exit 1
fi

echo "Checking if kubectl is installed..."
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install it first."
    exit 1
fi

echo "Initializing Terraform..."
terraform init

echo "Planning deployment..."
terraform plan

echo "Applying configuration..."
terraform apply -auto-approve

echo "Waiting for cluster to be ready..."
sleep 30

echo "Terraform deployment complete!"
echo "Access the app at: http://localhost:8080" 