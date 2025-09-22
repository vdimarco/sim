# Railway Quick Start Guide

## 🚀 Deploy in 5 Minutes

### 1. Install Railway CLI
```bash
npm install -g @railway/cli
```

### 2. Login to Railway
```bash
railway login
```

### 3. Deploy Your App
```bash
# Option A: Use the deployment script
bun run deploy:railway

# Option B: Manual deployment
railway link
railway up
```

### 4. Add Database
1. Go to your Railway project dashboard
2. Click "New" → "Database" → "PostgreSQL"
3. Railway will automatically set the `DATABASE_URL` environment variable

### 5. Set Environment Variables
In your Railway project dashboard, add these **required** variables:

```bash
NEXT_PUBLIC_APP_URL=https://your-app-name.railway.app
BETTER_AUTH_URL=https://your-app-name.railway.app
BETTER_AUTH_SECRET=your-32-character-secret-key
ENCRYPTION_KEY=your-32-character-encryption-key
INTERNAL_API_SECRET=your-32-character-api-secret
```

### 6. Run Database Migrations
```bash
railway run --service your-app-service bun run db:migrate
```

### 7. Test Your App
Visit your app URL and check the health endpoint:
- App: `https://your-app-name.railway.app`
- Health: `https://your-app-name.railway.app/api/health`

## 🔧 Useful Commands

```bash
# View logs
railway logs

# Open dashboard
railway open

# Run commands in your service
railway run <command>

# Check status
railway status
```

## 📚 Full Documentation
See [RAILWAY_DEPLOYMENT.md](./RAILWAY_DEPLOYMENT.md) for complete setup instructions.

