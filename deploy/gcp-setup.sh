#!/bin/bash

# Google Cloud Platform Setup Script for Sim
# This script sets up the necessary GCP resources for deploying Sim

set -e

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-buildz-ai}"
REGION="${GCP_REGION:-us-central1}"
ZONE="${GCP_ZONE:-us-central1-a}"
CLUSTER_NAME="${GCP_CLUSTER_NAME:-sim-cluster}"
DB_INSTANCE_NAME="${GCP_DB_INSTANCE:-sim-postgres}"
BUCKET_NAME="sim-storage-$(date +%s)"  # Unique bucket name

# Validate required tools
echo "🔍 Validating required tools..."
command -v gcloud >/dev/null 2>&1 || { echo "❌ gcloud is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed. Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ helm is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ docker is required but not installed. Aborting." >&2; exit 1; }

# Check if user is authenticated
echo "🔐 Checking authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ No active gcloud authentication found. Please run: gcloud auth login"
    exit 1
fi

echo "✅ All required tools are available and user is authenticated"

echo "🚀 Setting up Google Cloud Platform for Sim deployment..."

# Set the project
echo "📋 Setting project to $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable \
    container.googleapis.com \
    sqladmin.googleapis.com \
    storage.googleapis.com \
    secretmanager.googleapis.com \
    cloudbuild.googleapis.com \
    containerregistry.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com \
    compute.googleapis.com

# Create GKE cluster
echo "🏗️ Creating GKE cluster..."
gcloud container clusters create $CLUSTER_NAME \
    --zone=$ZONE \
    --num-nodes=3 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=10 \
    --machine-type=e2-standard-4 \
    --enable-autorepair \
    --enable-autoupgrade \
    --disk-size=100GB \
    --disk-type=pd-ssd \
    --enable-ip-alias \
    --network="default" \
    --subnetwork="default" \
    --enable-network-policy

# Get cluster credentials
echo "🔑 Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# Create Cloud SQL instance
echo "🗄️ Creating Cloud SQL PostgreSQL instance..."
gcloud sql instances create $DB_INSTANCE_NAME \
    --database-version=POSTGRES_15 \
    --tier=db-standard-2 \
    --region=$REGION \
    --storage-type=SSD \
    --storage-size=100GB \
    --storage-auto-increase \
    --backup \
    --enable-bin-log \
    --maintenance-window-day=SUN \
    --maintenance-window-hour=2 \
    --maintenance-release-channel=production

# Create database
echo "📊 Creating database..."
gcloud sql databases create sim --instance=$DB_INSTANCE_NAME

# Create database user
echo "👤 Creating database user..."
DB_PASSWORD=$(openssl rand -base64 32)
gcloud sql users create simuser --instance=$DB_INSTANCE_NAME --password=$DB_PASSWORD

# Create storage bucket
echo "🪣 Creating Cloud Storage bucket..."
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://$BUCKET_NAME

# Create secrets in Secret Manager
echo "🔐 Creating secrets in Secret Manager..."

# Generate secrets
BETTER_AUTH_SECRET=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
JWT_SECRET=$(openssl rand -hex 32)

# Create secrets
echo "$BETTER_AUTH_SECRET" | gcloud secrets create better-auth-secret --data-file=-
echo "$ENCRYPTION_KEY" | gcloud secrets create encryption-key --data-file=-
echo "$JWT_SECRET" | gcloud secrets create jwt-secret --data-file=-
echo "$DB_PASSWORD" | gcloud secrets create db-password --data-file=-

# Get connection details
DB_CONNECTION_NAME=$(gcloud sql instances describe $DB_INSTANCE_NAME --format="value(connectionName)")
DB_PRIVATE_IP=$(gcloud sql instances describe $DB_INSTANCE_NAME --format="value(ipAddresses[0].ipAddress)")

echo "✅ GCP setup complete!"
echo ""
echo "📋 Connection Details:"
echo "Project ID: $PROJECT_ID"
echo "Cluster: $CLUSTER_NAME"
echo "Database Instance: $DB_INSTANCE_NAME"
echo "Database Connection Name: $DB_CONNECTION_NAME"
echo "Database Private IP: $DB_PRIVATE_IP"
echo "Storage Bucket: $BUCKET_NAME"
echo ""
echo "🔐 Generated Secrets (also stored in Secret Manager):"
echo "Better Auth Secret: $BETTER_AUTH_SECRET"
echo "Encryption Key: $ENCRYPTION_KEY"
echo "JWT Secret: $JWT_SECRET"
echo "Database Password: $DB_PASSWORD"
echo ""
echo "Next steps:"
echo "1. Update the values in deploy/values-gcp.yaml with your configuration"
echo "2. Run: ./deploy/build-and-push.sh"
echo "3. Run: ./deploy/deploy-to-gke.sh"





