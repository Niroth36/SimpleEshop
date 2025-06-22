#!/bin/bash
# migrate-to-app-repo.sh

echo "🚀 Creating SimpleEshop Application Repository..."

# Create new directory for app repo
mkdir -p ../simpleeshop-app
cd ../simpleeshop-app

# Initialize git
git init
echo "# SimpleEshop Application" > README.md

# Copy application-specific files from original repo
cp -r ../SimpleEshop/web-app/ ./
cp -r ../SimpleEshop/serverless-functions/ ./
cp ../SimpleEshop/Dockerfile ./
cp ../SimpleEshop/Dockerfile.x86 ./
cp ../SimpleEshop/fixed-handler.js ./
cp ../SimpleEshop/docker-compose-dev.yml ./
cp ../SimpleEshop/docker-compose.yml ./
cp ../SimpleEshop/test-*.sh ./
cp ../SimpleEshop/run-all-tests.sh ./

# Create package.json at root if it doesn't exist
if [ ! -f package.json ]; then
cat > package.json << 'EOL'
{
  "name": "simpleeshop-app",
  "version": "1.0.0",
  "description": "SimpleEshop E-commerce Application",
  "main": "web-app/server.js",
  "scripts": {
    "start": "cd web-app && npm start",
    "dev": "cd web-app && npm run dev",
    "test": "cd web-app && npm test",
    "lint": "cd web-app && npm run lint",
    "build": "cd web-app && npm run build"
  },
  "keywords": ["ecommerce", "nodejs", "express"],
  "author": "Niroth"
}
EOL
fi

# Create .gitignore
cat > .gitignore << 'EOL'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Build outputs
build/
dist/
.next/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Docker
.dockerignore

# Logs
logs/
*.log
EOL

# Create .dockerignore
cat > .dockerignore << 'EOL'
node_modules/
npm-debug.log
.git
.gitignore
README.md
.env
.nyc_output
coverage
.nyc_output
.vscode
.idea
EOL

echo "✅ Application repository structure created!"
echo "📁 Location: $(pwd)"
echo ""
echo "🔄 Next steps:"
echo "1. Review the copied files"
echo "2. Create repository on GitHub: simpleeshop-app"
echo "3. Push to GitHub"