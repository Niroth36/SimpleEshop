# Sensitive Files Management Guide

## Overview

This document explains how to properly manage sensitive files in the SimpleEshop project, particularly focusing on Terraform configuration files, SSH configuration templates, and other files containing credentials or sensitive information.

## Recent Changes

We've updated the project's `.gitignore` file to exclude the following sensitive files:

1. **Terraform State Files**
   - `terraform.tfstate`
   - `terraform.tfstate.backup`
   - `infrastructure/azure/terraform.tfstate`
   - `infrastructure/azure/terraform.tfstate.backup`

2. **Terraform Variable Files**
   - `terraform.vars`
   - `infrastructure/azure/terraform.vars`
   - `infrastructure/azure/variables.tf`
   - Any `variables.tf` files in production directories

3. **SSH Configuration Files**
   - `ssh_config.tpl`
   - `infrastructure/azure/ssh_config.tpl`

## Cleaning Up Previously Tracked Files

If these files were previously tracked in git, simply updating the `.gitignore` file won't remove them from tracking. We've provided a cleanup script to help with this:

```bash
# Make the script executable
chmod +x cleanup-sensitive-files.sh

# Run the script
./cleanup-sensitive-files.sh
```

This script will:
1. Remove the sensitive files from git tracking without deleting them from your filesystem
2. Provide instructions for committing these changes

## Best Practices for Handling Sensitive Files

### Terraform State Files

Terraform state files contain sensitive information and should never be committed to version control. Instead:

1. **Use Remote State Storage**:
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "tfstate"
       storage_account_name = "tfstate023"
       container_name       = "tfstate"
       key                  = "simpleeshop.terraform.tfstate"
     }
   }
   ```

2. **Use State Locking**: Ensure your backend configuration supports state locking to prevent concurrent modifications.

### Variable Files

For Terraform variable files:

1. **Use Environment Variables** for sensitive values:
   ```bash
   export TF_VAR_db_password="your-secure-password"
   ```

2. **Create Template Files**: Instead of committing actual variable files, commit template files:
   ```bash
   # Create terraform.vars.template
   cp terraform.vars terraform.vars.template
   # Remove sensitive values from the template
   sed -i 's/actual_password/your_password_here/g' terraform.vars.template
   ```

   We've created the following template files as examples:
   - `infrastructure/azure/terraform.vars.template`
   - `infrastructure/azure/variables.tf.template`
   - `infrastructure/azure/ssh_config.tpl.template`

3. **Use Secret Management Tools**: Consider using HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault.

### SSH Configuration

For SSH configuration templates:

1. **Use Placeholders**: Replace actual hostnames, IPs, and credentials with placeholders in templates.

2. **Generate Configurations Dynamically**: Use scripts to generate actual configurations from templates and environment variables.

## Checking for Sensitive Files

Periodically check that no sensitive files are being tracked:

```bash
# Check if any sensitive files are still tracked
git ls-files | grep -E 'terraform\.tfstate|terraform\.vars|ssh_config\.tpl|variables\.tf'
```

## What to Do If Sensitive Data Is Committed

If sensitive data has already been committed:

1. **Change Any Exposed Credentials Immediately**

2. **Remove from Git History**:
   - For recent commits: `git filter-branch`
   - For larger repositories: [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)

3. **Force Push** to overwrite the remote repository history (use with caution)

## Additional Resources

- [Terraform Backend Configuration](https://www.terraform.io/docs/language/settings/backends/index.html)
- [Git - Removing Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [HashiCorp Vault](https://www.vaultproject.io/)
