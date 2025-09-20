#!/bin/bash

# Build and push Docker images to Google Container Registry
# This script builds all required images and pushes them to GCR

set -e

# Configuration
PROJECT_ID="buildz-ai"
REGISTRY="gcr.io/$PROJECT_ID"

# Validate required tools
echo "🔍 Validating required tools..."
command -v gcloud >/dev/null 2>&1 || { echo "❌ gcloud is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ docker is required but not installed. Aborting." >&2; exit 1; }

# Check if user is authenticated
echo "🔐 Checking authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ No active gcloud authentication found. Please run: gcloud auth login"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "✅ All required tools are available and user is authenticated"

echo "🐳 Building and pushing Docker images to GCR..."

# Authenticate with GCR
echo "🔐 Authenticating with Google Container Registry..."
gcloud auth configure-docker

# Build and push main application image
echo "🏗️ Building main application image..."
docker build -t $REGISTRY/simstudio:latest -f Dockerfile .
docker push $REGISTRY/simstudio:latest

# Build and push realtime service image
echo "🏗️ Building realtime service image..."
docker build -t $REGISTRY/realtime:latest -f docker/realtime.Dockerfile .
docker push $REGISTRY/realtime:latest

# Build and push migrations image
echo "🏗️ Building migrations image..."
docker build -t $REGISTRY/migrations:latest -f docker/migrations.Dockerfile .
docker push $REGISTRY/migrations:latest

echo "✅ All images built and pushed successfully!"
echo ""
echo "📋 Image URLs:"
echo "Main App: $REGISTRY/simstudio:latest"
echo "Realtime: $REGISTRY/realtime:latest"
echo "Migrations: $REGISTRY/migrations:latest"
echo ""
echo "Next step: Run ./deploy/deploy-to-gke.sh to deploy to GKE"




