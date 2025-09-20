#!/bin/bash

# Deploy Sim to Google Kubernetes Engine
# This script deploys the application using Helm

set -e

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-buildz-ai}"
CLUSTER_NAME="${GCP_CLUSTER_NAME:-sim-cluster}"
NAMESPACE="${GCP_NAMESPACE:-sim}"
RELEASE_NAME="${GCP_RELEASE_NAME:-sim}"
ZONE="${GCP_ZONE:-us-central1-a}"

# Validate required tools
echo "🔍 Validating required tools..."
command -v gcloud >/dev/null 2>&1 || { echo "❌ gcloud is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed. Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ helm is required but not installed. Aborting." >&2; exit 1; }

# Check if user is authenticated
echo "🔐 Checking authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ No active gcloud authentication found. Please run: gcloud auth login"
    exit 1
fi

echo "✅ All required tools are available and user is authenticated"

echo "🚀 Deploying Sim to Google Kubernetes Engine..."

# Ensure kubectl is configured
echo "🔧 Configuring kubectl..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# Create namespace if it doesn't exist
echo "📁 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create service account for Workload Identity
echo "👤 Creating service account for Workload Identity..."
gcloud iam service-accounts create sim-service-account \
    --display-name="Sim Service Account" \
    --description="Service account for Sim application"

# Grant necessary permissions
echo "🔑 Granting permissions to service account..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:sim-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:sim-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:sim-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

# Enable Workload Identity
echo "🔗 Enabling Workload Identity..."
gcloud iam service-accounts add-iam-policy-binding \
    sim-service-account@$PROJECT_ID.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$PROJECT_ID.svc.id.goog[sim/sim-service-account]"

# Annotate the Kubernetes service account
kubectl annotate serviceaccount sim-service-account \
    --namespace $NAMESPACE \
    iam.gke.io/gcp-service-account=sim-service-account@$PROJECT_ID.iam.gserviceaccount.com

# Create Cloud SQL proxy sidecar configuration
echo "🗄️ Creating Cloud SQL proxy configuration..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloud-sql-proxy-config
  namespace: $NAMESPACE
data:
  cloudsql-proxy.conf: |
    [cloudsql-proxy]
    instances = $PROJECT_ID:us-central1:sim-postgres
    port = 5432
    unix_socket = /cloudsql
EOF

# Create secrets from Secret Manager
echo "🔐 Creating secrets from Secret Manager..."
kubectl create secret generic sim-secrets \
    --from-literal=better-auth-secret="$(gcloud secrets versions access latest --secret=better-auth-secret)" \
    --from-literal=encryption-key="$(gcloud secrets versions access latest --secret=encryption-key)" \
    --from-literal=db-password="$(gcloud secrets versions access latest --secret=db-password)" \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

# Deploy using Helm
echo "📦 Deploying with Helm..."
helm upgrade --install $RELEASE_NAME ./helm/sim \
    --namespace $NAMESPACE \
    --values ./deploy/values-gcp.yaml \
    --set global.imageRegistry="gcr.io/$PROJECT_ID" \
    --set app.image.repository="gcr.io/$PROJECT_ID/simstudio" \
    --set realtime.image.repository="gcr.io/$PROJECT_ID/realtime" \
    --set migrations.image.repository="gcr.io/$PROJECT_ID/migrations" \
    --set externalDatabase.host="/cloudsql/$PROJECT_ID:us-central1:sim-postgres" \
    --set serviceAccount.annotations."iam\.gke\.io/gcp-service-account"="sim-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
    --wait

# Create managed SSL certificate
echo "🔒 Creating managed SSL certificate..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: sim-ssl-cert
  namespace: $NAMESPACE
spec:
  domains:
    - your-domain.com  # Replace with your actual domain
    - ws.your-domain.com  # Replace with your actual domain
EOF

# Reserve static IP
echo "🌐 Reserving static IP..."
gcloud compute addresses create sim-ip --global

# Get the IP address
STATIC_IP=$(gcloud compute addresses describe sim-ip --global --format="value(address)")
echo "📍 Static IP reserved: $STATIC_IP"

# Update DNS records (you'll need to do this manually)
echo "📝 DNS Configuration Required:"
echo "Please update your DNS records to point to: $STATIC_IP"
echo "Required records:"
echo "  your-domain.com -> $STATIC_IP"
echo "  ws.your-domain.com -> $STATIC_IP"

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/sim-app -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/sim-realtime -n $NAMESPACE

# Check deployment status
echo "📊 Deployment Status:"
kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE
kubectl get ingress -n $NAMESPACE

echo "✅ Deployment complete!"
echo ""
echo "🔗 Access your application at: https://your-domain.com"
echo "🔗 WebSocket endpoint: https://ws.your-domain.com"
echo ""
echo "📋 Useful commands:"
echo "  View logs: kubectl logs -f deployment/sim-app -n $NAMESPACE"
echo "  View realtime logs: kubectl logs -f deployment/sim-realtime -n $NAMESPACE"
echo "  Scale app: kubectl scale deployment sim-app --replicas=3 -n $NAMESPACE"
echo "  Port forward: kubectl port-forward service/sim-app 3000:3000 -n $NAMESPACE"





