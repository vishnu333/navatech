#!/bin/bash

echo "Deploying with Helm..."

cd helm

echo "Installing navatech-app..."
helm install navatech-app navatech-app/

echo "Helm deployment complete!" 