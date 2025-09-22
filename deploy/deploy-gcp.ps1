# Complete GCP Deployment Script for Sim (PowerShell version)
# This script handles the entire deployment process with proper error handling

param(
    [string]$ProjectId = "buildz-ai",
    [string]$Region = "us-central1",
    [string]$Zone = "us-central1-a",
    [string]$ClusterName = "sim-cluster",
    [string]$DbInstance = "sim-postgres",
    [string]$Namespace = "sim",
    [string]$ReleaseName = "sim",
    [string]$Domain = "buildz.ai",
    [string]$WsDomain = "ws.buildz.ai"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Function to check authentication
function Test-Auth {
    try {
        $activeAccount = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
        if (-not $activeAccount) {
            Write-Error "No active gcloud authentication found."
            Write-Status "Please run: gcloud auth login"
            exit 1
        }
    }
    catch {
        Write-Error "Failed to check gcloud authentication: $_"
        exit 1
    }
}

# Function to validate prerequisites
function Test-Prerequisites {
    Write-Status "Validating prerequisites..."
    
    $requiredTools = @("gcloud", "kubectl", "helm", "docker")
    $missingTools = @()
    
    foreach ($tool in $requiredTools) {
        if (-not (Test-Command $tool)) {
            $missingTools += $tool
        }
    }
    
    if ($missingTools.Count -gt 0) {
        Write-Error "Missing required tools: $($missingTools -join ', ')"
        Write-Status "Please install the missing tools and try again."
        exit 1
    }
    
    # Check if Docker is running
    try {
        docker info | Out-Null
    }
    catch {
        Write-Error "Docker is not running. Please start Docker and try again."
        exit 1
    }
    
    Test-Auth
    Write-Success "All prerequisites validated"
}

# Function to setup GCP infrastructure
function Setup-Infrastructure {
    Write-Status "Setting up GCP infrastructure..."
    
    # Set the project
    gcloud config set project $ProjectId
    
    # Enable required APIs
    Write-Status "Enabling required APIs..."
    gcloud services enable container.googleapis.com,sqladmin.googleapis.com,storage.googleapis.com,secretmanager.googleapis.com,cloudbuild.googleapis.com,containerregistry.googleapis.com,monitoring.googleapis.com,logging.googleapis.com,compute.googleapis.com --quiet
    
    # Check if cluster exists
    try {
        gcloud container clusters describe $ClusterName --zone=$Zone --quiet | Out-Null
        Write-Warning "Cluster $ClusterName already exists. Skipping cluster creation."
    }
    catch {
        Write-Status "Creating GKE cluster..."
        gcloud container clusters create $ClusterName --zone=$Zone --num-nodes=3 --enable-autoscaling --min-nodes=1 --max-nodes=10 --machine-type=e2-standard-4 --enable-autorepair --enable-autoupgrade --disk-size=100GB --disk-type=pd-ssd --enable-ip-alias --network="default" --subnetwork="default" --enable-network-policy --quiet
    }
    
    # Get cluster credentials
    Write-Status "Getting cluster credentials..."
    gcloud container clusters get-credentials $ClusterName --zone=$Zone
    
    # Check if Cloud SQL instance exists
    try {
        gcloud sql instances describe $DbInstance --quiet | Out-Null
        Write-Warning "Cloud SQL instance $DbInstance already exists. Skipping database creation."
    }
    catch {
        Write-Status "Creating Cloud SQL PostgreSQL instance..."
        gcloud sql instances create $DbInstance --database-version=POSTGRES_15 --tier=db-standard-2 --region=$Region --storage-type=SSD --storage-size=100GB --storage-auto-increase --backup --enable-bin-log --maintenance-window-day=SUN --maintenance-window-hour=2 --maintenance-release-channel=production --quiet
        
        # Create database
        Write-Status "Creating database..."
        gcloud sql databases create sim --instance=$DbInstance --quiet
        
        # Create database user
        Write-Status "Creating database user..."
        $dbPassword = -join ((1..32) | ForEach {Get-Random -InputObject @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9')})
        gcloud sql users create simuser --instance=$DbInstance --password=$dbPassword --quiet
        
        # Store password in Secret Manager
        $dbPassword | gcloud secrets create db-password --data-file=- --quiet
    }
    
    # Create secrets in Secret Manager (if they don't exist)
    Write-Status "Creating secrets in Secret Manager..."
    
    try {
        gcloud secrets describe better-auth-secret --quiet | Out-Null
    }
    catch {
        $betterAuthSecret = -join ((1..32) | ForEach {Get-Random -InputObject @('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f')})
        $betterAuthSecret | gcloud secrets create better-auth-secret --data-file=- --quiet
    }
    
    try {
        gcloud secrets describe encryption-key --quiet | Out-Null
    }
    catch {
        $encryptionKey = -join ((1..32) | ForEach {Get-Random -InputObject @('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f')})
        $encryptionKey | gcloud secrets create encryption-key --data-file=- --quiet
    }
    
    try {
        gcloud secrets describe jwt-secret --quiet | Out-Null
    }
    catch {
        $jwtSecret = -join ((1..32) | ForEach {Get-Random -InputObject @('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f')})
        $jwtSecret | gcloud secrets create jwt-secret --data-file=- --quiet
    }
    
    Write-Success "Infrastructure setup complete"
}

# Function to build and push Docker images
function Build-AndPushImages {
    Write-Status "Building and pushing Docker images..."
    
    $registry = "gcr.io/$ProjectId"
    
    # Authenticate with GCR
    gcloud auth configure-docker --quiet
    
    # Build and push main application image
    Write-Status "Building main application image..."
    docker build -t "$registry/simstudio:latest" -f Dockerfile .
    docker push "$registry/simstudio:latest"
    
    # Build and push realtime service image
    Write-Status "Building realtime service image..."
    docker build -t "$registry/realtime:latest" -f docker/realtime.Dockerfile .
    docker push "$registry/realtime:latest"
    
    # Build and push migrations image
    Write-Status "Building migrations image..."
    docker build -t "$registry/migrations:latest" -f docker/migrations.Dockerfile .
    docker push "$registry/migrations:latest"
    
    Write-Success "All images built and pushed successfully"
}

# Function to deploy to GKE
function Deploy-ToGke {
    Write-Status "Deploying to GKE..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
    
    # Create service account for Workload Identity
    Write-Status "Setting up Workload Identity..."
    
    # Check if service account exists
    try {
        gcloud iam service-accounts describe "sim-service-account@$ProjectId.iam.gserviceaccount.com" --quiet | Out-Null
    }
    catch {
        gcloud iam service-accounts create sim-service-account --display-name="Sim Service Account" --description="Service account for Sim application" --quiet
        
        # Grant necessary permissions
        gcloud projects add-iam-policy-binding $ProjectId --member="serviceAccount:sim-service-account@$ProjectId.iam.gserviceaccount.com" --role="roles/cloudsql.client" --quiet
        gcloud projects add-iam-policy-binding $ProjectId --member="serviceAccount:sim-service-account@$ProjectId.iam.gserviceaccount.com" --role="roles/storage.objectViewer" --quiet
        gcloud projects add-iam-policy-binding $ProjectId --member="serviceAccount:sim-service-account@$ProjectId.iam.gserviceaccount.com" --role="roles/secretmanager.secretAccessor" --quiet
    }
    
    # Enable Workload Identity
    gcloud iam service-accounts add-iam-policy-binding "sim-service-account@$ProjectId.iam.gserviceaccount.com" --role roles/iam.workloadIdentityUser --member "serviceAccount:$ProjectId.svc.id.goog[$Namespace/sim-service-account]" --quiet
    
    # Create Kubernetes service account
    kubectl create serviceaccount sim-service-account --namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
    
    # Annotate the Kubernetes service account
    kubectl annotate serviceaccount sim-service-account --namespace $Namespace "iam.gke.io/gcp-service-account=sim-service-account@$ProjectId.iam.gserviceaccount.com" --overwrite
    
    # Create secrets from Secret Manager
    Write-Status "Creating secrets from Secret Manager..."
    $betterAuthSecret = gcloud secrets versions access latest --secret=better-auth-secret
    $encryptionKey = gcloud secrets versions access latest --secret=encryption-key
    $dbPassword = gcloud secrets versions access latest --secret=db-password
    
    kubectl create secret generic sim-secrets --from-literal=better-auth-secret=$betterAuthSecret --from-literal=encryption-key=$encryptionKey --from-literal=db-password=$dbPassword --namespace=$Namespace --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy using Helm
    Write-Status "Deploying with Helm..."
    helm upgrade --install $ReleaseName ./helm/sim --namespace $Namespace --values ./deploy/values-gcp.yaml --set global.imageRegistry="gcr.io/$ProjectId" --set app.image.repository="gcr.io/$ProjectId/simstudio" --set realtime.image.repository="gcr.io/$ProjectId/realtime" --set migrations.image.repository="gcr.io/$ProjectId/migrations" --set externalDatabase.host="/cloudsql/$ProjectId`:$Region`:$DbInstance" --set serviceAccount.annotations."iam\.gke\.io/gcp-service-account"="sim-service-account@$ProjectId.iam.gserviceaccount.com" --set ingress.app.host=$Domain --set ingress.realtime.host=$WsDomain --wait
    
    Write-Success "Deployment complete"
}

# Function to setup ingress and SSL
function Setup-Ingress {
    Write-Status "Setting up ingress and SSL..."
    
    # Create managed SSL certificate
    $certYaml = @"
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: sim-ssl-cert
  namespace: $Namespace
spec:
  domains:
    - $Domain
    - $WsDomain
"@
    
    $certYaml | kubectl apply -f -
    
    # Reserve static IP if it doesn't exist
    try {
        gcloud compute addresses describe sim-ip --global --quiet | Out-Null
    }
    catch {
        Write-Status "Reserving static IP..."
        gcloud compute addresses create sim-ip --global --quiet
    }
    
    # Get the IP address
    $staticIp = gcloud compute addresses describe sim-ip --global --format="value(address)"
    Write-Success "Static IP reserved: $staticIp"
    
    Write-Warning "Please update your DNS records:"
    Write-Status "  $Domain -> $staticIp"
    Write-Status "  $WsDomain -> $staticIp"
}

# Function to check deployment status
function Test-Deployment {
    Write-Status "Checking deployment status..."
    
    # Wait for deployment to be ready
    Write-Status "Waiting for deployments to be ready..."
    try {
        kubectl wait --for=condition=available --timeout=300s deployment/sim-app -n $Namespace
    }
    catch {
        Write-Warning "sim-app deployment not ready within timeout"
    }
    
    try {
        kubectl wait --for=condition=available --timeout=300s deployment/sim-realtime -n $Namespace
    }
    catch {
        Write-Warning "sim-realtime deployment not ready within timeout"
    }
    
    # Show status
    Write-Status "Deployment Status:"
    kubectl get pods -n $Namespace
    kubectl get services -n $Namespace
    kubectl get ingress -n $Namespace
    
    # Get the static IP
    try {
        $staticIp = gcloud compute addresses describe sim-ip --global --format="value(address)"
        Write-Success "Deployment complete!"
        Write-Status "Access your application at: https://$Domain"
        Write-Status "WebSocket endpoint: https://$WsDomain"
        Write-Status "Static IP: $staticIp"
    }
    catch {
        Write-Warning "Could not retrieve static IP"
    }
}

# Main execution
function Main {
    Write-Status "Starting Sim GCP deployment..."
    Write-Status "Project: $ProjectId"
    Write-Status "Region: $Region"
    Write-Status "Zone: $Zone"
    Write-Status "Cluster: $ClusterName"
    Write-Status "Domain: $Domain"
    Write-Status "WebSocket Domain: $WsDomain"
    Write-Host ""
    
    Test-Prerequisites
    Setup-Infrastructure
    Build-AndPushImages
    Deploy-ToGke
    Setup-Ingress
    Test-Deployment
    
    Write-Success "🎉 Sim deployment completed successfully!"
}

# Run main function
Main

