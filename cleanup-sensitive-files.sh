#!/bin/bash

# Script to remove sensitive files from git tracking without deleting them
# This is useful after updating .gitignore to exclude files that were previously tracked

echo "🔒 Removing sensitive files from git tracking (without deleting them)..."
echo "This script will help clean up sensitive files that are already tracked by git."
echo "The files will remain on your filesystem but will no longer be tracked by git."
echo ""

# Check if there are any uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
  echo "⚠️ WARNING: You have uncommitted changes in your repository."
  echo "It's recommended to commit or stash your changes before running this script."
  read -p "Do you want to continue anyway? (y/n): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
  fi
fi

# List of sensitive files to untrack
SENSITIVE_FILES=(
  "infrastructure/azure/ssh_config.tpl"
  "infrastructure/azure/terraform.tfstate"
  "infrastructure/azure/terraform.tfstate.backup"
  "infrastructure/azure/terraform.vars"
  "infrastructure/azure/variables.tf"
)

# Remove files from git tracking but keep them on disk
for file in "${SENSITIVE_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Removing $file from git tracking..."
    git rm --cached "$file"
    echo "✅ $file is no longer tracked by git but still exists on your filesystem."
  else
    echo "⚠️ $file not found, skipping."
  fi
done

echo ""
echo "🔒 Sensitive files have been removed from git tracking."
echo "To complete the process, commit these changes:"
echo "git commit -m \"Remove sensitive files from git tracking\""
echo ""
echo "⚠️ IMPORTANT: These files still exist in your git history!"
echo "If you need to completely remove them from git history, consider using:"
echo "git filter-branch or BFG Repo-Cleaner (https://rtyley.github.io/bfg-repo-cleaner/)"