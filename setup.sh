#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "🚀 Blackhole YAML Engine Setup Started..."

# 1. Create structure
mkdir -p backend/app/{routes,models,utils,exporters}
mkdir -p frontend/src/{pages,components}

# 2. Backend files
cat > backend/requirements.txt <<EOF
fastapi==0.115.2
uvicorn==0.30.6
pydantic==2.8.2
pydantic-settings==2.4.0
SQLAlchemy==2.0.34
alembic==1.13.2
python-multipart==0.0.9
PyYAML==6.0.2
httpx==0.27.2
EOF

cat > backend/app/main.py <<EOF
from fastapi import FastAPI
from app.routes import process

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}

app.include_router(process.router, prefix="/process")
EOF

cat > backend/app/routes/process.py <<EOF
from fastapi import APIRouter

router = APIRouter()

@router.post("/")
async def process_yml(yml: dict):
    return {"received": yml}
EOF

# 3. Frontend files
cat > frontend/package.json <<EOF
{
  "name": "blackhole-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev -p 3000"
  },
  "dependencies": {
    "next": "14.2.0",
    "react": "18.2.0",
    "react-dom": "18.2.0"
  }
}
EOF

cat > frontend/src/pages/index.tsx <<EOF
import React from "react";

export default function Home() {
  return <h1>🚀 Blackhole YAML Engine Frontend Ready</h1>;
}
EOF

# 4. Setup venv
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r backend/requirements.txt

# 5. Frontend install
cd frontend
npm install
cd ..

# 6. Run backend & frontend in background
nohup uvicorn app.main:app --app-dir backend/app --host 0.0.0.0 --port 8000 > backend.log 2>&1 &
cd frontend && nohup npm run dev > ../frontend.log 2>&1 &

echo "✅ Blackhole YAML Engine Ready!"
echo "Backend → http://127.0.0.1:8000/health"
echo "Frontend → http://127.0.0.1:3000/"
