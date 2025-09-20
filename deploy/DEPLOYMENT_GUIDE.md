# Sim Deployment Guide for buildz.ai on GCP

This guide will help you deploy Sim to Google Cloud Platform for buildz.ai.

## Prerequisites

1. **Google Cloud SDK** installed and configured
2. **kubectl** installed
3. **Helm** installed (v3.x)
4. **Docker** installed
5. **Domain ownership** of buildz.ai and ws.buildz.ai

## Step 1: Prerequisites

Before starting, ensure you have the following installed and configured:

### Required Tools
- **Google Cloud SDK** (gcloud CLI)
- **kubectl** (Kubernetes CLI)
- **Helm** (Kubernetes package manager)
- **Docker** (Container runtime)

### Installation Commands

**Windows (PowerShell)**:
```powershell
# Install Google Cloud SDK
winget install Google.CloudSDK

# Install kubectl
gcloud components install kubectl

# Install Helm
choco install kubernetes-helm

# Install Docker Desktop
winget install Docker.DockerDesktop
```

**macOS/Linux**:
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash

# Install kubectl
gcloud components install kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Docker
# Follow instructions at https://docs.docker.com/get-docker/
```

### Authentication

```bash
# Set the project (replace with your project ID)
gcloud config set project YOUR_PROJECT_ID

# Authenticate
gcloud auth login
gcloud auth application-default login

# Verify authentication
gcloud auth list
```

## Step 2: Quick Deployment (Recommended)

Use the comprehensive deployment script that handles everything:

**Windows (PowerShell)**:
```powershell
# Run the PowerShell deployment script
.\deploy\deploy-gcp.ps1 -ProjectId "your-project-id" -Domain "your-domain.com" -WsDomain "ws.your-domain.com"
```

**macOS/Linux**:
```bash
# Make script executable and run
chmod +x deploy/deploy-gcp.sh
./deploy/deploy-gcp.sh
```

This single script will:
- ✅ Validate prerequisites and authentication
- ✅ Create GKE cluster (sim-cluster)
- ✅ Create Cloud SQL PostgreSQL instance (sim-postgres)
- ✅ Set up Secret Manager with generated secrets
- ✅ Build and push all Docker images
- ✅ Deploy to GKE using Helm
- ✅ Configure ingress and SSL certificates
- ✅ Reserve static IP address

## Step 3: Manual Deployment (Alternative)

If you prefer to run each step manually:

### 3.1 Create Infrastructure
```bash
chmod +x deploy/gcp-setup.sh
./deploy/gcp-setup.sh
```

### 3.2 Build and Push Images
```bash
chmod +x deploy/build-and-push.sh
./deploy/build-and-push.sh
```

### 3.3 Deploy to GKE
```bash
chmod +x deploy/deploy-to-gke.sh
./deploy/deploy-to-gke.sh
```

## Step 5: Configure DNS

After deployment, you'll get a static IP address. Update your DNS records:

1. **A record**: `buildz.ai` → Static IP
2. **A record**: `ws.buildz.ai` → Static IP

## Step 6: Verify Deployment

Check the deployment status:

```bash
# Check pods
kubectl get pods -n sim

# Check services
kubectl get services -n sim

# Check ingress
kubectl get ingress -n sim

# View logs
kubectl logs -f deployment/sim-app -n sim
kubectl logs -f deployment/sim-realtime -n sim
```

## Configuration

### Required Environment Variables

The following secrets are automatically generated and stored in Google Secret Manager:

- `better-auth-secret`: Authentication secret
- `encryption-key`: Data encryption key
- `jwt-secret`: JWT signing secret
- `db-password`: Database password

### Optional Environment Variables

You can add these via the Helm values or Secret Manager:

- `OPENAI_API_KEY`: OpenAI API key
- `ANTHROPIC_API_KEY_1`: Anthropic API key
- `RESEND_API_KEY`: Email service API key
- `GOOGLE_CLIENT_ID`: Google OAuth client ID
- `GOOGLE_CLIENT_SECRET`: Google OAuth client secret

## Monitoring

The deployment includes:

- **Health checks** for all services
- **Horizontal Pod Autoscaler** for automatic scaling
- **Pod Disruption Budget** for high availability
- **Google Cloud Operations** integration for monitoring

## Scaling

To scale the application:

```bash
# Scale main app
kubectl scale deployment sim-app --replicas=3 -n sim

# Scale realtime service
kubectl scale deployment sim-realtime --replicas=3 -n sim
```

## Troubleshooting

If you encounter issues during deployment, check the comprehensive troubleshooting guide:

📖 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Complete troubleshooting guide

### Quick Fixes

1. **Authentication Issues**:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Docker Not Running**:
   - Start Docker Desktop
   - Wait for full initialization

3. **Missing Tools**:
   - Install required tools (see Prerequisites section)
   - Restart terminal after installation

4. **Deployment Failures**:
   ```bash
   # Check pod status
   kubectl get pods -n sim
   
   # Check logs
   kubectl logs -f deployment/sim-app -n sim
   ```

### Common Issues

1. **Pod startup failures**: Check resource limits and secrets
2. **Database connection issues**: Verify Cloud SQL proxy configuration
3. **Ingress not working**: Check DNS configuration and SSL certificates
4. **Authentication errors**: Re-run `gcloud auth login`
5. **Docker build failures**: Check Docker is running and has sufficient resources

### Useful Commands

```bash
# Port forward for local testing
kubectl port-forward service/sim-app 3000:3000 -n sim

# Check secret values
kubectl get secret sim-secrets -n sim -o yaml

# View detailed pod information
kubectl describe pod <pod-name> -n sim

# Check ingress status
kubectl describe ingress sim-ingress -n sim
```

## Security

The deployment includes:

- **Workload Identity** for secure GCP service access
- **Network policies** for pod-to-pod communication
- **TLS termination** at the ingress level
- **Non-root containers** for security

## Cost Optimization

- **Autoscaling** reduces costs during low usage
- **Preemptible nodes** can be enabled for development
- **Resource requests** are set to prevent over-provisioning

## Support

For issues or questions:
- Check the logs: `kubectl logs -f deployment/sim-app -n sim`
- Review the Helm values: `helm get values sim -n sim`
- Check GCP Console for infrastructure issues
