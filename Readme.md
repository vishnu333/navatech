# 🚀 Navatech Kubernetes Assignment

A robust, production-grade Kubernetes environment demonstrating high availability and scalability.

## 📋 Assignment Requirements Met

### ✅ Core Requirements
- [x] **Kubernetes Cluster Setup** - Using Kind (Kubernetes in Docker)
- [x] **NGINX Ingress Controller** - Deployed and configured
- [x] **Highly Available Application** - 3 replicas with proper resource limits
- [x] **Zero-Downtime Updates** - Rolling update strategy implemented
- [x] **Resource Management** - CPU and memory limits configured

### ✅ Bonus Features
- [x] **Infrastructure as Code** - Terraform automation
- [x] **Stateful Database** - PostgreSQL StatefulSet
- [x] **Comprehensive Documentation** - Complete setup guide

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Navatech K8s Cluster                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Control   │  │   Worker    │  │   Worker    │        │
│  │   Plane     │  │   Node 1    │  │   Node 2    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│                    NGINX Ingress Controller                │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   App Pod   │  │   App Pod   │  │   App Pod   │        │
│  │   (nginx)   │  │   (nginx)   │  │   (nginx)   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│                    PostgreSQL StatefulSet                  │
│  ┌─────────────┐                                          │
│  │  Postgres   │                                          │
│  │   Pod       │                                          │
│  └─────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
```

## 🛠️ Prerequisites

- **Docker** - For running Kind cluster
- **Kind** - Kubernetes in Docker
- **kubectl** - Kubernetes command-line tool
- **Terraform** (optional) - For infrastructure automation

## 🚀 Quick Start

### 1. Automated Setup (Recommended)

```sh
# Clone the repository
git clone https://github.com/vishnu333/navatech.git
cd navatech

# Run the automated setup script
./scripts/setup-cluster.sh
```

### 2. Manual Setup

#### Step 1: Create Kind Cluster

```sh
# Create cluster with 3 nodes
kind create cluster --name navatech-cluster --config kind-config.yaml

# Verify cluster
kubectl get nodes
```

#### Step 2: Install NGINX Ingress Controller

```sh
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
```

#### Step 3: Deploy Application

```sh
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Create ConfigMaps
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/html-configmap.yaml

# Deploy PostgreSQL
kubectl apply -f k8s/postgres-statefulset.yaml

# Deploy application
kubectl apply -f k8s/deployment.yaml

# Create service
kubectl apply -f k8s/service.yaml

# Create ingress
kubectl apply -f k8s/ingress.yaml
```

#### Step 4: Access the Application

```sh
# Add to /etc/hosts (optional)
echo "127.0.0.1 navatech.local" | sudo tee -a /etc/hosts

# Port forward for local access
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80
```

Access the application at: http://localhost:8080

## 📊 Kubernetes Manifests

### Core Application Components

#### Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: navatech-app
```

#### Deployment (High Availability)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: navatech-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

#### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: navatech-app-service
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: navatech-app
```

#### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: navatech-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: navatech.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: navatech-app-service
            port:
              number: 80
```

### Stateful Database (PostgreSQL)

#### StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-service
  replicas: 1
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_DB
          value: "navatech_db"
        - name: POSTGRES_USER
          value: "navatech_user"
        - name: POSTGRES_PASSWORD
          value: "navatech_password"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

## 🔧 Infrastructure as Code (Terraform)

### Setup Terraform

```sh
# Install Terraform (if not installed)
brew install terraform

# Initialize Terraform
cd terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### Terraform Features

- **Namespace Management** - Automatic namespace creation
- **ConfigMap Management** - Dynamic configuration updates
- **Deployment Automation** - Rolling updates with zero downtime
- **Service Discovery** - Automatic service creation
- **Ingress Configuration** - Automated ingress setup

## 📈 High Availability Features

### 1. **Multi-Node Cluster**
- 1 Control Plane + 2 Worker Nodes
- Distributed workload across nodes

### 2. **Application Replicas**
- 3 application replicas for redundancy
- Automatic load balancing

### 3. **Zero-Downtime Updates**

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

### 4. **Health Checks**
- **Liveness Probe** - Restarts unhealthy pods
- **Readiness Probe** - Ensures traffic only to ready pods

### 5. **Resource Management**
- **Requests**: 512Mi memory, 500m CPU
- **Limits**: 1Gi memory, 1000m CPU

## 🔍 Verification Commands

### Check Cluster Status

```sh
# Check nodes
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Check services
kubectl get svc --all-namespaces
```

### Check Application Status

```sh
# Check application pods
kubectl get pods -n navatech-app

# Check application services
kubectl get svc -n navatech-app

# Check ingress
kubectl get ingress -n navatech-app

# Check PostgreSQL
kubectl get pods -n navatech-app -l app=postgres
```

### Test Application

```sh
# Test health endpoint
curl http://localhost:8080/health

# Test main application
curl http://localhost:8080/
```

### Check Logs

```sh
# Check application logs
kubectl logs -n navatech-app -l app=navatech-app

# Check PostgreSQL logs
kubectl logs -n navatech-app -l app=postgres
```

## 🧪 Testing Zero-Downtime Updates

### Test Rolling Update

```sh
# Update the deployment image
kubectl set image deployment/navatech-app nginx=nginx:1.26-alpine -n navatech-app

# Watch the rolling update
kubectl rollout status deployment/navatech-app -n navatech-app

# Check that all pods are ready
kubectl get pods -n navatech-app
```

### Test Application Access During Update

```sh
# Continuously test the application during update
while true; do
  curl -s http://localhost:8080/health
  sleep 1
done
```

## 🗄️ Database Features

### PostgreSQL StatefulSet
- **Persistent Storage** - 1Gi PVC
- **Stateful Identity** - Stable network identity
- **Ordered Deployment** - Sequential pod creation
- **Health Checks** - pg_isready integration

### Database Access

```sh
# Connect to PostgreSQL
kubectl exec -it postgres-0 -n navatech-app -- psql -U navatech_user -d navatech_db

# Check database status
kubectl exec -it postgres-0 -n navatech-app -- pg_isready -U navatech_user -d navatech_db
```

## 🧹 Cleanup

### Remove Cluster

```sh
# Delete the Kind cluster
kind delete cluster --name navatech-cluster
```

### Remove Terraform Resources

```sh
cd terraform
terraform destroy
```

## 📸 Screenshots

### Cluster Status

```sh
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces
```

### Application Access
- **URL**: http://localhost:8080
- **Health Check**: http://localhost:8080/health

## 🔧 Troubleshooting

### Common Issues

#### 1. Port Already in Use

```sh
# Kill existing port forward
pkill -f "kubectl port-forward"

# Start new port forward
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80
```

#### 2. Pod Not Ready

```sh
# Check pod events
kubectl describe pod <pod-name> -n navatech-app

# Check pod logs
kubectl logs <pod-name> -n navatech-app
```

#### 3. Ingress Not Working

```sh
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress status
kubectl describe ingress navatech-app-ingress -n navatech-app
```

## 📚 Additional Resources

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)

## 🤝 Contributing

This is an assignment submission. For questions or issues, please contact the repository owner.

---

**🎉 Assignment completed with all requirements and bonus features implemented!**