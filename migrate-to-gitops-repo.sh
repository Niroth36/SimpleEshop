#!/bin/bash
# migrate-to-gitops-repo.sh

echo "🔄 Creating SimpleEshop GitOps Repository..."

# Create new directory for gitops repo
mkdir -p ../simpleeshop-gitops
cd ../simpleeshop-gitops

# Initialize git
git init
echo "# SimpleEshop GitOps" > README.md

# Create directory structure
mkdir -p applications/simpleeshop
mkdir -p applications/database
mkdir -p argocd-applications

# Copy and modify application manifests
cp ../SimpleEshop/kubernetes/applications/* applications/simpleeshop/
cp ../SimpleEshop/kubernetes/database/* applications/database/

# Copy ArgoCD applications
cp ../SimpleEshop/kubernetes/argocd/applications/* argocd-applications/

# Create updated ArgoCD applications that point to this GitOps repo
cat > argocd-applications/simpleeshop-app.yaml << 'EOL'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: simpleeshop
  namespace: argocd
  labels:
    app: simpleeshop
spec:
  project: default
  source:
    repoURL: https://github.com/Niroth36/simpleeshop-gitops.git
    targetRevision: main
    path: applications/simpleeshop
  destination:
    server: https://kubernetes.default.svc
    namespace: simpleeshop
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - ApplyOutOfSyncOnly=true
  revisionHistoryLimit: 10
EOL

cat > argocd-applications/database-app.yaml << 'EOL'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: database
  namespace: argocd
  labels:
    app: database
spec:
  project: default
  source:
    repoURL: https://github.com/Niroth36/simpleeshop-gitops.git
    targetRevision: main
    path: applications/database
  destination:
    server: https://kubernetes.default.svc
    namespace: simpleeshop
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - ApplyOutOfSyncOnly=true
  revisionHistoryLimit: 10
EOL

# Create kustomization.yaml for better organization
cat > applications/kustomization.yaml << 'EOL'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - simpleeshop/
  - database/

commonLabels:
  environment: production
  managed-by: argocd
EOL

# Create .gitignore
cat > .gitignore << 'EOL'
# Temporary files
*.tmp
*.swp
*.swo

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
EOL

echo "✅ GitOps repository structure created!"
echo "📁 Location: $(pwd)"
echo ""
echo "🔄 Next steps:"
echo "1. Review the manifest files"
echo "2. Create repository on GitHub: simpleeshop-gitops"
echo "3. Push to GitHub"
echo "4. Update ArgoCD applications to point to new repo"