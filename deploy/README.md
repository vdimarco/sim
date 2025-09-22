# Sim Deployment on Google Cloud Platform

This directory contains all the necessary files and scripts to deploy Sim to Google Cloud Platform using Google Kubernetes Engine (GKE).

## Architecture Overview

The deployment includes:
- **Main Application**: Next.js app running on port 3000
- **Realtime Service**: Socket.io server running on port 3002
- **Database**: Cloud SQL PostgreSQL with pgvector extension
- **Storage**: Cloud Storage for file uploads and static assets
- **Monitoring**: Google Cloud Operations (Stackdriver) integration
- **Load Balancer**: Google Cloud Load Balancer with SSL termination

## Prerequisites

1. **Google Cloud CLI** installed and authenticated
2. **Docker** installed locally
3. **Helm 3.x** installed
4. **kubectl** installed
5. **Domain name** for your application (optional but recommended)

## Quick Start

### 1. Initial Setup

```bash
# Clone the repository
git clone https://github.com/simstudioai/sim.git
cd sim

# Make scripts executable
chmod +x deploy/*.sh

# Edit configuration files
# Update PROJECT_ID in all files with your actual GCP project ID
# Update domain names in values-gcp.yaml with your actual domain
```

### 2. Configure GCP Resources

```bash
# Run the setup script (this will create all necessary GCP resources)
./deploy/gcp-setup.sh
```

This script will:
- Enable required APIs
- Create a GKE cluster
- Set up Cloud SQL PostgreSQL instance
- Create Cloud Storage bucket
- Set up Secret Manager
- Generate secure secrets

### 3. Build and Push Images

```bash
# Build and push Docker images to Google Container Registry
./deploy/build-and-push.sh
```

### 4. Deploy to GKE

```bash
# Deploy the application to GKE
./deploy/deploy-to-gke.sh
```

## Configuration Files

### `values-gcp.yaml`
Main configuration file with GCP-optimized settings:
- Resource limits and requests
- Environment variables
- Service configurations
- Ingress settings
- Monitoring configuration

### `gcp-setup.sh`
Initial setup script that creates all necessary GCP resources.

### `build-and-push.sh`
Builds and pushes Docker images to Google Container Registry.

### `deploy-to-gke.sh`
Deploys the application to GKE using Helm.

### `monitoring.yaml`
Sets up monitoring, logging, and alerting with Google Cloud Operations.

## Environment Variables

The following environment variables need to be configured:

### Required
- `BETTER_AUTH_SECRET`: Authentication secret (auto-generated)
- `ENCRYPTION_KEY`: Encryption key (auto-generated)
- `DATABASE_URL`: Cloud SQL connection string (auto-generated)

### Optional but Recommended
- `RESEND_API_KEY`: For transactional emails
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`: For Google OAuth
- `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET`: For GitHub OAuth
- `OPENAI_API_KEY`: For OpenAI integration
- `ANTHROPIC_API_KEY_1`: For Anthropic Claude integration

## DNS Configuration

After deployment, you'll need to configure your DNS:

1. **Reserve a static IP** (done automatically by the script)
2. **Update DNS records** to point to the static IP:
   - `your-domain.com` → Static IP
   - `ws.your-domain.com` → Static IP (for WebSocket connections)

## Monitoring and Logging

The deployment includes:
- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Google Cloud Logging** for centralized logging
- **Google Cloud Monitoring** for alerting

Access monitoring:
- Grafana: `http://your-grafana-loadbalancer-ip:3000`
- Prometheus: `kubectl port-forward service/prometheus 9090:9090 -n sim`

## Scaling

### Horizontal Scaling
```bash
# Scale the main application
kubectl scale deployment sim-app --replicas=5 -n sim

# Scale the realtime service
kubectl scale deployment sim-realtime --replicas=3 -n sim
```

### Vertical Scaling
Edit `values-gcp.yaml` and update resource limits:
```yaml
resources:
  limits:
    memory: "8Gi"
    cpu: "4000m"
  requests:
    memory: "4Gi"
    cpu: "2000m"
```

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n sim
kubectl describe pod <pod-name> -n sim
```

### View Logs
```bash
# Main application logs
kubectl logs -f deployment/sim-app -n sim

# Realtime service logs
kubectl logs -f deployment/sim-realtime -n sim

# Database migration logs
kubectl logs -f job/sim-migrations -n sim
```

### Check Services
```bash
kubectl get services -n sim
kubectl get ingress -n sim
```

### Database Connection Issues
```bash
# Check Cloud SQL proxy
kubectl logs -f deployment/cloud-sql-proxy -n sim

# Test database connection
kubectl exec -it deployment/sim-app -n sim -- psql $DATABASE_URL
```

## Security Considerations

1. **Secrets Management**: All sensitive data is stored in Google Secret Manager
2. **Network Policies**: Restrictive network policies are applied
3. **Workload Identity**: Uses Google's Workload Identity for secure service-to-service authentication
4. **SSL/TLS**: Managed SSL certificates for HTTPS
5. **Private IP**: Database uses private IP for enhanced security

## Cost Optimization

1. **Preemptible Nodes**: Consider using preemptible nodes for non-critical workloads
2. **Resource Limits**: Set appropriate resource limits to avoid over-provisioning
3. **Auto-scaling**: Enable horizontal pod autoscaling
4. **Storage**: Use appropriate storage classes based on performance needs

## Backup and Recovery

1. **Database Backups**: Cloud SQL automatic backups are enabled
2. **Application State**: Stateless application design
3. **Configuration**: All configuration is stored in Git and Helm charts

## Support

For issues and questions:
- GitHub Issues: https://github.com/simstudioai/sim/issues
- Documentation: https://docs.sim.ai
- Support Email: help@sim.ai





