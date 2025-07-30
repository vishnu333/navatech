#!/bin/bash

echo "Setting up with Terraform..."

cd terraform

echo "Initializing Terraform..."
terraform init

echo "Planning deployment..."
terraform plan

echo "Applying configuration..."
terraform apply -auto-approve

echo "Terraform deployment complete!" 