# GCP Deployment Troubleshooting Guide

This guide helps you troubleshoot common issues when deploying Sim to Google Cloud Platform.

## Prerequisites Issues

### 1. Authentication Problems

**Error**: `No active gcloud authentication found`

**Solution**:
```bash
# Login to Google Cloud
gcloud auth login

# Set application default credentials
gcloud auth application-default login

# Verify authentication
gcloud auth list
```

### 2. Missing Tools

**Error**: `gcloud/kubectl/helm/docker is required but not installed`

**Solutions**:

**Install Google Cloud SDK**:
- Windows: Download from [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- Or use: `winget install Google.CloudSDK`

**Install kubectl**:
```bash
# Windows
gcloud components install kubectl

# Or download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

**Install Helm**:
```bash
# Windows (using Chocolatey)
choco install kubernetes-helm

# Or download from: https://helm.sh/docs/intro/install/
```

**Install Docker**:
- Download Docker Desktop from [Docker](https://www.docker.com/products/docker-desktop)

### 3. Docker Not Running

**Error**: `Docker is not running`

**Solution**:
1. Start Docker Desktop
2. Wait for it to fully initialize
3. Verify with: `docker info`

## Infrastructure Issues

### 1. Project Not Found

**Error**: `Project 'buildz-ai' not found`

**Solution**:
```bash
# List available projects
gcloud projects list

# Set the correct project
gcloud config set project YOUR_PROJECT_ID
```

### 2. API Not Enabled

**Error**: `API [container.googleapis.com] not enabled`

**Solution**:
```bash
# Enable required APIs
gcloud services enable container.googleapis.com sqladmin.googleapis.com storage.googleapis.com secretmanager.googleapis.com cloudbuild.googleapis.com containerregistry.googleapis.com monitoring.googleapis.com logging.googleapis.com compute.googleapis.com
```

### 3. Quota Exceeded

**Error**: `Quota exceeded for resource 'CPUS'`

**Solution**:
1. Check your quotas in GCP Console
2. Request quota increase if needed
3. Use smaller machine types: `--machine-type=e2-small`

### 4. Cluster Creation Fails

**Error**: `Cluster creation failed`

**Common Causes**:
- Insufficient permissions
- Resource quotas exceeded
- Invalid zone/region

**Solution**:
```bash
# Check your permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID

# Try a different zone
gcloud container clusters create sim-cluster --zone=us-central1-b
```

## Database Issues

### 1. Cloud SQL Instance Creation Fails

**Error**: `Cloud SQL instance creation failed`

**Common Causes**:
- Invalid instance name
- Insufficient permissions
- Quota exceeded

**Solution**:
```bash
# Check if instance name is valid (lowercase, no special chars)
# Use a different name if needed
gcloud sql instances create sim-postgres-new --database-version=POSTGRES_15 --tier=db-standard-2 --region=us-central1
```

### 2. Database Connection Issues

**Error**: `Database connection failed`

**Solution**:
1. Check if Cloud SQL proxy is running
2. Verify connection string in values-gcp.yaml
3. Check firewall rules allow database access

## Image Build Issues

### 1. Docker Build Fails

**Error**: `Docker build failed`

**Common Causes**:
- Missing Dockerfile
- Build context issues
- Resource constraints

**Solution**:
```bash
# Test build locally first
docker build -t test-image -f Dockerfile .

# Check Docker resources
docker system df
docker system prune  # Clean up if needed
```

### 2. Image Push Fails

**Error**: `Image push failed`

**Solution**:
```bash
# Re-authenticate with GCR
gcloud auth configure-docker

# Check if registry exists
gcloud container images list
```

## Deployment Issues

### 1. Helm Installation Fails

**Error**: `Helm installation failed`

**Solution**:
```bash
# Check Helm version
helm version

# Update Helm if needed
helm repo update

# Check if chart is valid
helm lint ./helm/sim
```

### 2. Pod Startup Failures

**Error**: `Pod startup failed`

**Debug Steps**:
```bash
# Check pod status
kubectl get pods -n sim

# Check pod logs
kubectl logs -f deployment/sim-app -n sim

# Describe pod for events
kubectl describe pod <pod-name> -n sim
```

### 3. Service Account Issues

**Error**: `Workload Identity binding failed`

**Solution**:
```bash
# Check service account exists
gcloud iam service-accounts list

# Recreate service account if needed
gcloud iam service-accounts create sim-service-account --display-name="Sim Service Account"
```

## Ingress Issues

### 1. SSL Certificate Not Provisioned

**Error**: `SSL certificate not ready`

**Solution**:
1. Check if domains are correctly configured
2. Verify DNS records point to the static IP
3. Wait for certificate provisioning (can take up to 1 hour)

### 2. Ingress Not Working

**Error**: `Ingress not accessible`

**Debug Steps**:
```bash
# Check ingress status
kubectl get ingress -n sim

# Check ingress events
kubectl describe ingress sim-ingress -n sim

# Check if static IP is assigned
gcloud compute addresses list
```

## Common Solutions

### 1. Reset Everything

If you need to start over:

```bash
# Delete cluster
gcloud container clusters delete sim-cluster --zone=us-central1-a

# Delete Cloud SQL instance
gcloud sql instances delete sim-postgres

# Delete static IP
gcloud compute addresses delete sim-ip --global

# Delete secrets
gcloud secrets delete better-auth-secret
gcloud secrets delete encryption-key
gcloud secrets delete jwt-secret
gcloud secrets delete db-password
```

### 2. Partial Deployment Recovery

If deployment partially failed:

```bash
# Check what's deployed
kubectl get all -n sim

# Delete failed resources
kubectl delete deployment sim-app -n sim
kubectl delete service sim-app -n sim

# Redeploy
helm upgrade --install sim ./helm/sim --namespace sim --values ./deploy/values-gcp.yaml
```

### 3. Resource Cleanup

To clean up resources:

```bash
# Delete Helm release
helm uninstall sim -n sim

# Delete namespace
kubectl delete namespace sim

# Delete cluster
gcloud container clusters delete sim-cluster --zone=us-central1-a
```

## Getting Help

1. **Check logs**: Always check pod logs first
2. **GCP Console**: Use the GCP Console to inspect resources
3. **Documentation**: Refer to [GCP documentation](https://cloud.google.com/docs)
4. **Community**: Ask on [Stack Overflow](https://stackoverflow.com) with `google-cloud-platform` tag

## Useful Commands

```bash
# Check cluster status
gcloud container clusters describe sim-cluster --zone=us-central1-a

# Get cluster credentials
gcloud container clusters get-credentials sim-cluster --zone=us-central1-a

# Check all resources
kubectl get all -n sim

# Port forward for testing
kubectl port-forward service/sim-app 3000:3000 -n sim

# Check logs
kubectl logs -f deployment/sim-app -n sim

# Scale deployment
kubectl scale deployment sim-app --replicas=3 -n sim
```

