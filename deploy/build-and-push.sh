#!/bin/bash

# Build and push Docker images to Google Container Registry
# This script builds all required images and pushes them to GCR

set -e

# Configuration
PROJECT_ID="buildz-ai"
REGISTRY="gcr.io/$PROJECT_ID"

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




