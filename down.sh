#!/bin/bash

set -e

echo "🛑 Starting Hetzner Cloud GitHub Runner cleanup..."

if [ ! -f "terraform.tfstate" ]; then
    echo "❌ No terraform.tfstate file found. Nothing to destroy."
    exit 0
fi

if ! command -v terraform &> /dev/null; then
    echo "❌ Error: Terraform is not installed!"
    exit 1
fi

echo "🔍 Planning destruction..."
terraform plan -destroy

echo ""
read -p "⚠️  Are you sure you want to destroy the infrastructure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Destruction cancelled."
    exit 0
fi

echo "🗑️  Destroying infrastructure..."
terraform destroy -auto-approve

echo ""
echo "✅ Infrastructure destroyed successfully!"
echo "🧹 Cleanup complete."