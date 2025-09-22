#!/bin/bash

# Complete GCP Deployment Script for Sim
# This script handles the entire deployment process with proper error handling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration with environment variable support
PROJECT_ID="${GCP_PROJECT_ID:-buildz-ai}"
REGION="${GCP_REGION:-us-central1}"
ZONE="${GCP_ZONE:-us-central1-a}"
CLUSTER_NAME="${GCP_CLUSTER_NAME:-sim-cluster}"
DB_INSTANCE_NAME="${GCP_DB_INSTANCE:-sim-postgres}"
NAMESPACE="${GCP_NAMESPACE:-sim}"
RELEASE_NAME="${GCP_RELEASE_NAME:-sim}"
DOMAIN="${GCP_DOMAIN:-buildz.ai}"
WS_DOMAIN="${GCP_WS_DOMAIN:-ws.buildz.ai}"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check authentication
check_auth() {
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "No active gcloud authentication found."
        print_status "Please run: gcloud auth login"
        exit 1
    fi
}

# Function to validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    local missing_tools=()
    
    if ! command_exists gcloud; then
        missing_tools+=("gcloud")
    fi
    
    if ! command_exists kubectl; then
        missing_tools+=("kubectl")
    fi
    
    if ! command_exists helm; then
        missing_tools+=("helm")
    fi
    
    if ! command_exists docker; then
        missing_tools+=("docker")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_status "Please install the missing tools and try again."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    check_auth
    print_success "All prerequisites validated"
}

# Function to setup GCP infrastructure
setup_infrastructure() {
    print_status "Setting up GCP infrastructure..."
    
    # Set the project
    gcloud config set project $PROJECT_ID
    
    # Enable required APIs
    print_status "Enabling required APIs..."
    gcloud services enable \
        container.googleapis.com \
        sqladmin.googleapis.com \
        storage.googleapis.com \
        secretmanager.googleapis.com \
        cloudbuild.googleapis.com \
        containerregistry.googleapis.com \
        monitoring.googleapis.com \
        logging.googleapis.com \
        compute.googleapis.com \
        --quiet
    
    # Check if cluster exists
    if gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE --quiet >/dev/null 2>&1; then
        print_warning "Cluster $CLUSTER_NAME already exists. Skipping cluster creation."
    else
        print_status "Creating GKE cluster..."
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
            --enable-network-policy \
            --quiet
    fi
    
    # Get cluster credentials
    print_status "Getting cluster credentials..."
    gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE
    
    # Check if Cloud SQL instance exists
    if gcloud sql instances describe $DB_INSTANCE_NAME --quiet >/dev/null 2>&1; then
        print_warning "Cloud SQL instance $DB_INSTANCE_NAME already exists. Skipping database creation."
    else
        print_status "Creating Cloud SQL PostgreSQL instance..."
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
            --maintenance-release-channel=production \
            --quiet
        
        # Create database
        print_status "Creating database..."
        gcloud sql databases create sim --instance=$DB_INSTANCE_NAME --quiet
        
        # Create database user
        print_status "Creating database user..."
        DB_PASSWORD=$(openssl rand -base64 32)
        gcloud sql users create simuser --instance=$DB_INSTANCE_NAME --password=$DB_PASSWORD --quiet
        
        # Store password in Secret Manager
        echo "$DB_PASSWORD" | gcloud secrets create db-password --data-file=- --quiet
    fi
    
    # Create secrets in Secret Manager (if they don't exist)
    print_status "Creating secrets in Secret Manager..."
    
    if ! gcloud secrets describe better-auth-secret --quiet >/dev/null 2>&1; then
        BETTER_AUTH_SECRET=$(openssl rand -hex 32)
        echo "$BETTER_AUTH_SECRET" | gcloud secrets create better-auth-secret --data-file=- --quiet
    fi
    
    if ! gcloud secrets describe encryption-key --quiet >/dev/null 2>&1; then
        ENCRYPTION_KEY=$(openssl rand -hex 32)
        echo "$ENCRYPTION_KEY" | gcloud secrets create encryption-key --data-file=- --quiet
    fi
    
    if ! gcloud secrets describe jwt-secret --quiet >/dev/null 2>&1; then
        JWT_SECRET=$(openssl rand -hex 32)
        echo "$JWT_SECRET" | gcloud secrets create jwt-secret --data-file=- --quiet
    fi
    
    print_success "Infrastructure setup complete"
}

# Function to build and push Docker images
build_and_push_images() {
    print_status "Building and pushing Docker images..."
    
    REGISTRY="gcr.io/$PROJECT_ID"
    
    # Authenticate with GCR
    gcloud auth configure-docker --quiet
    
    # Build and push main application image
    print_status "Building main application image..."
    docker build -t $REGISTRY/simstudio:latest -f Dockerfile .
    docker push $REGISTRY/simstudio:latest
    
    # Build and push realtime service image
    print_status "Building realtime service image..."
    docker build -t $REGISTRY/realtime:latest -f docker/realtime.Dockerfile .
    docker push $REGISTRY/realtime:latest
    
    # Build and push migrations image
    print_status "Building migrations image..."
    docker build -t $REGISTRY/migrations:latest -f docker/migrations.Dockerfile .
    docker push $REGISTRY/migrations:latest
    
    print_success "All images built and pushed successfully"
}

# Function to deploy to GKE
deploy_to_gke() {
    print_status "Deploying to GKE..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Create service account for Workload Identity
    print_status "Setting up Workload Identity..."
    
    # Check if service account exists
    if ! gcloud iam service-accounts describe sim-service-account@$PROJECT_ID.iam.gserviceaccount.com --quiet >/dev/null 2>&1; then
        gcloud iam service-accounts create sim-service-account \
            --display-name="Sim Service Account" \
            --description="Service account for Sim application" \
            --quiet
        
        # Grant necessary permissions
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:sim-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
            --role="roles/cloudsql.client" \
            --quiet
        
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:sim-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
            --role="roles/storage.objectViewer" \
            --quiet
        
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:sim-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
            --role="roles/secretmanager.secretAccessor" \
            --quiet
    fi
    
    # Enable Workload Identity
    gcloud iam service-accounts add-iam-policy-binding \
        sim-service-account@$PROJECT_ID.iam.gserviceaccount.com \
        --role roles/iam.workloadIdentityUser \
        --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/sim-service-account]" \
        --quiet
    
    # Create Kubernetes service account
    kubectl create serviceaccount sim-service-account --namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Annotate the Kubernetes service account
    kubectl annotate serviceaccount sim-service-account \
        --namespace $NAMESPACE \
        iam.gke.io/gcp-service-account=sim-service-account@$PROJECT_ID.iam.gserviceaccount.com \
        --overwrite
    
    # Create secrets from Secret Manager
    print_status "Creating secrets from Secret Manager..."
    kubectl create secret generic sim-secrets \
        --from-literal=better-auth-secret="$(gcloud secrets versions access latest --secret=better-auth-secret)" \
        --from-literal=encryption-key="$(gcloud secrets versions access latest --secret=encryption-key)" \
        --from-literal=db-password="$(gcloud secrets versions access latest --secret=db-password)" \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy using Helm
    print_status "Deploying with Helm..."
    helm upgrade --install $RELEASE_NAME ./helm/sim \
        --namespace $NAMESPACE \
        --values ./deploy/values-gcp.yaml \
        --set global.imageRegistry="gcr.io/$PROJECT_ID" \
        --set app.image.repository="gcr.io/$PROJECT_ID/simstudio" \
        --set realtime.image.repository="gcr.io/$PROJECT_ID/realtime" \
        --set migrations.image.repository="gcr.io/$PROJECT_ID/migrations" \
        --set externalDatabase.host="/cloudsql/$PROJECT_ID:$REGION:$DB_INSTANCE_NAME" \
        --set serviceAccount.annotations."iam\.gke\.io/gcp-service-account"="sim-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
        --set ingress.app.host="$DOMAIN" \
        --set ingress.realtime.host="$WS_DOMAIN" \
        --wait
    
    print_success "Deployment complete"
}

# Function to setup ingress and SSL
setup_ingress() {
    print_status "Setting up ingress and SSL..."
    
    # Create managed SSL certificate
    cat <<EOF | kubectl apply -f -
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: sim-ssl-cert
  namespace: $NAMESPACE
spec:
  domains:
    - $DOMAIN
    - $WS_DOMAIN
EOF
    
    # Reserve static IP if it doesn't exist
    if ! gcloud compute addresses describe sim-ip --global --quiet >/dev/null 2>&1; then
        print_status "Reserving static IP..."
        gcloud compute addresses create sim-ip --global --quiet
    fi
    
    # Get the IP address
    STATIC_IP=$(gcloud compute addresses describe sim-ip --global --format="value(address)")
    print_success "Static IP reserved: $STATIC_IP"
    
    print_warning "Please update your DNS records:"
    print_status "  $DOMAIN -> $STATIC_IP"
    print_status "  $WS_DOMAIN -> $STATIC_IP"
}

# Function to check deployment status
check_deployment() {
    print_status "Checking deployment status..."
    
    # Wait for deployment to be ready
    print_status "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/sim-app -n $NAMESPACE || true
    kubectl wait --for=condition=available --timeout=300s deployment/sim-realtime -n $NAMESPACE || true
    
    # Show status
    print_status "Deployment Status:"
    kubectl get pods -n $NAMESPACE
    kubectl get services -n $NAMESPACE
    kubectl get ingress -n $NAMESPACE
    
    # Get the static IP
    STATIC_IP=$(gcloud compute addresses describe sim-ip --global --format="value(address)" 2>/dev/null || echo "Not available")
    
    print_success "Deployment complete!"
    print_status "Access your application at: https://$DOMAIN"
    print_status "WebSocket endpoint: https://$WS_DOMAIN"
    print_status "Static IP: $STATIC_IP"
}

# Main execution
main() {
    print_status "Starting Sim GCP deployment..."
    print_status "Project: $PROJECT_ID"
    print_status "Region: $REGION"
    print_status "Zone: $ZONE"
    print_status "Cluster: $CLUSTER_NAME"
    print_status "Domain: $DOMAIN"
    print_status "WebSocket Domain: $WS_DOMAIN"
    echo
    
    validate_prerequisites
    setup_infrastructure
    build_and_push_images
    deploy_to_gke
    setup_ingress
    check_deployment
    
    print_success "🎉 Sim deployment completed successfully!"
}

# Run main function
main "$@"

