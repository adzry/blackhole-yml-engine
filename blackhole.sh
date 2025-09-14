#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "🔥 Summoning Blackhole Jet Turbo X with Telegram Notifier..."

# 1. Backend Procfile
mkdir -p backend
cat > backend/Procfile <<'EOF'
web: uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
EOF
echo "✅ Backend Procfile created."

# 2. Railway config
cat > railway.json <<'EOF'
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "nixpacksPlan": {
      "phases": {
        "install": {
          "dependsOn": ["setup"],
          "cmds": ["pip install -r backend/requirements.txt"]
        },
        "start": {
          "cmd": "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"
        }
      }
    }
  }
}
EOF

# 3. Render config
cat > render.yaml <<'EOF'
services:
  - type: web
    name: blackhole-backend
    env: python
    buildCommand: pip install -r backend/requirements.txt
    startCommand: uvicorn app.main:app --host 0.0.0.0 --port $PORT
    envVars:
      - key: PORT
        value: 8000
EOF

# 4. Vercel config
cat > vercel.json <<'EOF'
{
  "version": 2,
  "builds": [
    {
      "src": "frontend/next.config.js",
      "use": "@vercel/next"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "https://blackhole-api.up.railway.app/$1"
    }
  ]
}
EOF

# 5. Frontend env
mkdir -p frontend
cat > frontend/.env.local <<'EOF'
NEXT_PUBLIC_API_URL=https://blackhole-api.up.railway.app
EOF

# 6. GitHub Actions CI/CD Workflows
mkdir -p .github/workflows

# Backend + Frontend auto-deploy
cat > .github/workflows/deploy.yml <<'EOF'
name: 🚀 Blackhole Auto Deploy

on:
  push:
    branches: [ "main" ]

jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy Backend to Railway
        uses: railwayapp/actions@v2
        with:
          railwayToken: ${{ secrets.RAILWAY_TOKEN }}
          serviceId: ${{ secrets.RAILWAY_SERVICE_ID }}

  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy Frontend to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./frontend
EOF

# Watchdog job (health check + Telegram notify)
cat > .github/workflows/watchdog.yml <<'EOF'
name: 🐺 Blackhole Watchdog

on:
  schedule:
    - cron: "*/10 * * * *" # every 10 minutes

jobs:
  healthcheck:
    runs-on: ubuntu-latest
    steps:
      - name: Check API Health
        run: |
          status=$(curl -s -o /dev/null -w "%{http_code}" https://blackhole-api.up.railway.app/health || echo "000")

          if [ "$status" != "200" ]; then
            echo "❌ API unhealthy ($status)"

            # Send Telegram DOWN alert
            curl -s -X POST https://api.telegram.org/bot${{ secrets.TELEGRAM_BOT_TOKEN }}/sendMessage \
              -d chat_id=${{ secrets.TELEGRAM_CHAT_ID }} \
              -d text="🚨 Blackhole API DOWN! Status: $status. Triggering redeploy."

            exit 1
          else
            echo "✅ API healthy ($status)"

            # Send Telegram RECOVERY alert
            curl -s -X POST https://api.telegram.org/bot${{ secrets.TELEGRAM_BOT_TOKEN }}/sendMessage \
              -d chat_id=${{ secrets.TELEGRAM_CHAT_ID }} \
              -d text="✅ Blackhole API recovered. Status: $status"
          fi
EOF

# 7. Inject badges in README
if ! grep -q "Deploy on Railway" README.md; then
cat >> README.md <<'EOF'

---

## 🚀 One-Click Deploy
[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/new?repo=https://github.com/adzry/blackhole-yml-engine)
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/adzry/blackhole-yml-engine&project-name=blackhole-frontend&repository-name=blackhole-yml-engine)
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/adzry/blackhole-yml-engine)

---

## ⚡ CI/CD Status
- Backend → Railway ![Railway Status](https://img.shields.io/badge/backend-railway-blue)
- Frontend → Vercel ![Vercel Status](https://img.shields.io/badge/frontend-vercel-green)
- Watchdog → Auto heal every 10 min 🐺
- Telegram → Alerts when API down/recovered 📲
EOF
fi

# 8. Git auto-commit
git add backend/Procfile railway.json render.yaml vercel.json frontend/.env.local .github/workflows README.md
git commit -m "🔥 Jet Turbo X + Telegram Notifier injected"
git push origin main

echo "🎯 Blackhole Jet Turbo X with Telegram deployed!"
echo "👉 Next: Add GitHub Secrets: RAILWAY_TOKEN, RAILWAY_SERVICE_ID, VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID, TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID"
echo "📲 Telegram alerts active!"
