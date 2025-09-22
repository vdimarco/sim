# Railway Deployment Script for Sim Studio
# This script helps prepare and deploy the application to Railway

Write-Host "🚀 Starting Railway deployment process..." -ForegroundColor Green

# Check if Railway CLI is installed
try {
    railway --version | Out-Null
    Write-Host "✅ Railway CLI is ready" -ForegroundColor Green
} catch {
    Write-Host "❌ Railway CLI is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   npm install -g @railway/cli" -ForegroundColor Yellow
    Write-Host "   or visit: https://docs.railway.app/develop/cli" -ForegroundColor Yellow
    exit 1
}

# Check if user is logged in
try {
    railway whoami | Out-Null
    Write-Host "✅ Logged in to Railway" -ForegroundColor Green
} catch {
    Write-Host "❌ Please log in to Railway first:" -ForegroundColor Red
    Write-Host "   railway login" -ForegroundColor Yellow
    exit 1
}

# Check if project is linked
try {
    railway status | Out-Null
    Write-Host "✅ Project is linked" -ForegroundColor Green
} catch {
    Write-Host "🔗 Linking to Railway project..." -ForegroundColor Yellow
    railway link
}

Write-Host "📦 Installing dependencies..." -ForegroundColor Blue
bun install --frozen-lockfile

Write-Host "🔨 Building application..." -ForegroundColor Blue
bun run build

Write-Host "🚀 Deploying to Railway..." -ForegroundColor Blue
railway up

Write-Host "✅ Deployment complete!" -ForegroundColor Green

# Get the domain
try {
    $domain = railway domain
    Write-Host "🌐 Your app should be available at: https://$domain" -ForegroundColor Cyan
} catch {
    Write-Host "🌐 Check your Railway dashboard for the app URL" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Set up your environment variables in the Railway dashboard" -ForegroundColor White
Write-Host "2. Add a PostgreSQL database service" -ForegroundColor White
Write-Host "3. Run database migrations: railway run --service your-app-service bun run db:migrate" -ForegroundColor White
Write-Host "4. Test your deployment at the provided URL" -ForegroundColor White

Write-Host ""
Write-Host "🔧 Useful commands:" -ForegroundColor Yellow
Write-Host "- View logs: railway logs" -ForegroundColor White
Write-Host "- Open dashboard: railway open" -ForegroundColor White
Write-Host "- Run commands: railway run <command>" -ForegroundColor White

