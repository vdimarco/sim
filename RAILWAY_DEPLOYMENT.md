# Railway Deployment Guide for Sim Studio

This guide will help you deploy the Sim Studio application to Railway.

## Prerequisites

1. A Railway account (sign up at [railway.app](https://railway.app))
2. A GitHub repository with your code
3. Required external services (see Environment Variables section)

## Step 1: Create Railway Project

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Choose your repository
5. Railway will automatically detect the `railway.json` configuration

## Step 2: Add Database Service

Your application requires a PostgreSQL database. Add it to your Railway project:

1. In your Railway project dashboard, click "New"
2. Select "Database" → "PostgreSQL"
3. Railway will automatically provision a PostgreSQL database
4. Note the connection details (you'll need these for environment variables)

## Step 3: Configure Environment Variables

Go to your service settings and add the following environment variables:

### Required Environment Variables

```bash
# Core Application
NODE_ENV=production
NEXT_PUBLIC_APP_URL=https://your-app-name.railway.app

# Database
DATABASE_URL=postgresql://username:password@host:port/database
# (Railway will provide this automatically for the PostgreSQL service)

# Authentication (Better Auth)
BETTER_AUTH_URL=https://your-app-name.railway.app
BETTER_AUTH_SECRET=your-32-character-secret-key
ENCRYPTION_KEY=your-32-character-encryption-key
INTERNAL_API_SECRET=your-32-character-api-secret

# Optional but Recommended
DISABLE_REGISTRATION=false
LOG_LEVEL=INFO
```

### Optional Environment Variables

Add these based on your needs:

```bash
# Redis (for caching/sessions)
REDIS_URL=redis://username:password@host:port

# Payment Processing
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...

# Email Service
RESEND_API_KEY=re_...

# AI/LLM Providers (choose one or more)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GROQ_API_KEY=gsk_...

# File Storage
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_S3_BUCKET_NAME=your-bucket-name
AWS_S3_REGION=us-east-1

# Monitoring
SENTRY_DSN=https://...
SENTRY_ORG=your-org
SENTRY_PROJECT=your-project
SENTRY_AUTH_TOKEN=your-token

# Browser Automation (if using Stagehand)
BROWSERBASE_API_KEY=your-api-key
BROWSERBASE_PROJECT_ID=your-project-id
```

## Step 4: Deploy

1. Railway will automatically deploy when you push to your main branch
2. Monitor the deployment logs in the Railway dashboard
3. Once deployed, your app will be available at `https://your-app-name.railway.app`

## Step 5: Database Migration

After deployment, you may need to run database migrations:

1. Connect to your Railway project via CLI:
   ```bash
   npm install -g @railway/cli
   railway login
   railway link
   ```

2. Run database migrations:
   ```bash
   railway run --service your-app-service bun run db:migrate
   ```

## Step 6: Verify Deployment

1. Check the health endpoint: `https://your-app-name.railway.app/api/health`
2. Test the main application functionality
3. Verify database connectivity
4. Check logs for any errors

## Troubleshooting

### Common Issues

1. **Build Failures**: Check that all dependencies are properly installed and the build command works locally
2. **Database Connection**: Ensure `DATABASE_URL` is correctly set and the database is accessible
3. **Environment Variables**: Verify all required environment variables are set
4. **Memory Issues**: Railway has memory limits; consider upgrading if needed

### Logs

View logs in the Railway dashboard or via CLI:
```bash
railway logs
```

### Scaling

- Railway automatically scales based on traffic
- Monitor resource usage in the dashboard
- Consider upgrading to a paid plan for production use

## Security Considerations

1. **Environment Variables**: Never commit sensitive data to your repository
2. **HTTPS**: Railway provides HTTPS by default
3. **Database**: Use strong passwords and consider IP restrictions
4. **API Keys**: Rotate keys regularly and use least-privilege access

## Monitoring

1. Use Railway's built-in monitoring
2. Set up external monitoring (e.g., Sentry, DataDog)
3. Monitor database performance
4. Set up alerts for critical issues

## Support

- Railway Documentation: [docs.railway.app](https://docs.railway.app)
- Railway Discord: [discord.gg/railway](https://discord.gg/railway)
- Project Issues: Create an issue in your GitHub repository

