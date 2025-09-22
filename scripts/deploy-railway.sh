#!/bin/bash

# Railway Deployment Script for Sim Studio
# This script helps prepare and deploy the application to Railway

set -e

echo "🚀 Starting Railway deployment process..."

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI is not installed. Please install it first:"
    echo "   npm install -g @railway/cli"
    echo "   or visit: https://docs.railway.app/develop/cli"
    exit 1
fi

# Check if user is logged in
if ! railway whoami &> /dev/null; then
    echo "❌ Please log in to Railway first:"
    echo "   railway login"
    exit 1
fi

echo "✅ Railway CLI is ready"

# Check if project is linked
if ! railway status &> /dev/null; then
    echo "🔗 Linking to Railway project..."
    railway link
fi

echo "📦 Installing dependencies..."
bun install --frozen-lockfile

echo "🔨 Building application..."
bun run build

echo "🚀 Deploying to Railway..."
railway up

echo "✅ Deployment complete!"
echo "🌐 Your app should be available at: https://$(railway domain)"

echo ""
echo "📋 Next steps:"
echo "1. Set up your environment variables in the Railway dashboard"
echo "2. Add a PostgreSQL database service"
echo "3. Run database migrations: railway run --service your-app-service bun run db:migrate"
echo "4. Test your deployment at the provided URL"

echo ""
echo "🔧 Useful commands:"
echo "- View logs: railway logs"
echo "- Open dashboard: railway open"
echo "- Run commands: railway run <command>"

