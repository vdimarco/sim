# Sim Deployment Guide for buildz.ai on GCP

This guide will help you deploy Sim to Google Cloud Platform for buildz.ai.

## Prerequisites

1. **Google Cloud SDK** installed and configured
2. **kubectl** installed
3. **Helm** installed (v3.x)
4. **Docker** installed
5. **Domain ownership** of buildz.ai and ws.buildz.ai

## Step 1: GCP Project Setup

First, ensure you have the buildz-ai project set up and authenticated:

```bash
# Set the project
gcloud config set project buildz-ai

# Authenticate
gcloud auth login
gcloud auth application-default login
```

## Step 2: Create Infrastructure

Run the GCP setup script to create all necessary resources:

```bash
chmod +x deploy/gcp-setup.sh
./deploy/gcp-setup.sh
```

This will create:
- GKE cluster (sim-cluster)
- Cloud SQL PostgreSQL instance (sim-postgres)
- Cloud Storage bucket
- Secret Manager secrets
- Service accounts with proper permissions

## Step 3: Build and Push Docker Images

Build and push all required Docker images to Google Container Registry:

```bash
chmod +x deploy/build-and-push.sh
./deploy/build-and-push.sh
```

This will build and push:
- Main application (simstudio)
- Realtime service (realtime)
- Database migrations (migrations)

## Step 4: Deploy to GKE

Deploy the application using Helm:

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

### Common Issues

1. **Pod startup failures**: Check resource limits and secrets
2. **Database connection issues**: Verify Cloud SQL proxy configuration
3. **Ingress not working**: Check DNS configuration and SSL certificates

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
