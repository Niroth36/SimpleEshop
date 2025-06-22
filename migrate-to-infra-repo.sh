#!/bin/bash
# migrate-to-infra-repo.sh

echo "🏗️ Creating SimpleEshop Infrastructure Repository..."

# Create new directory for infrastructure repo
mkdir -p ../simpleeshop-infrastructure
cd ../simpleeshop-infrastructure

# Initialize git
git init
echo "# SimpleEshop Infrastructure" > README.md

# Copy infrastructure-related folders
cp -r ../SimpleEshop/ansible/ ./
cp -r ../SimpleEshop/infrastructure/ ./terraform/
cp -r ../SimpleEshop/monitoring/ ./
cp -r ../SimpleEshop/ci-cd/ ./
cp -r ../SimpleEshop/database/ ./

# Copy Kubernetes infrastructure (not application manifests)
mkdir -p kubernetes
cp -r ../SimpleEshop/kubernetes/namespaces/ kubernetes/
cp -r ../SimpleEshop/kubernetes/jenkins/ kubernetes/
cp -r ../SimpleEshop/kubernetes/scripts/ kubernetes/

# Copy scripts
mkdir -p scripts
cp ../SimpleEshop/check-system.sh scripts/

# Create additional infrastructure scripts
cat > scripts/deploy-infrastructure.sh << 'EOL'
#!/bin/bash
# Deploy complete infrastructure

echo "🚀 Deploying SimpleEshop Infrastructure..."

# Deploy Terraform infrastructure
echo "📦 Deploying Azure infrastructure..."
cd terraform/
terraform init
terraform plan
terraform apply -auto-approve
cd ..

# Deploy Kubernetes base components
echo "☸️ Deploying Kubernetes infrastructure..."
cd kubernetes/
./scripts/deploy-all.sh
cd ..

echo "✅ Infrastructure deployment complete!"
EOL

chmod +x scripts/deploy-infrastructure.sh

# Create .gitignore for infrastructure
cat > .gitignore << 'EOL'
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
*.tfvars
*.tfplan

# Ansible
*.retry
.vault_pass

# SSH keys
*.pem
*.key
id_rsa*

# Environment files
.env
.env.*

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Temporary files
tmp/
temp/
EOL

# Update existing files to remove application-specific content
echo "📝 Cleaning up infrastructure-specific configurations..."

# Remove application manifests from kubernetes folder if copied
rm -rf kubernetes/applications/ 2>/dev/null || true
rm -rf kubernetes/database/ 2>/dev/null || true

echo "✅ Infrastructure repository structure created!"
echo "📁 Location: $(pwd)"
echo ""
echo "🔄 Next steps:"
echo "1. Review the infrastructure files"
echo "2. Update Terraform variables for your environment"
echo "3. Create repository on GitHub: simpleeshop-infrastructure"
echo "4. Push to GitHub"