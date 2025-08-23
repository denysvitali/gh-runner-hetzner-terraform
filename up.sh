#!/bin/bash

set -e

echo "🚀 Starting Hetzner Cloud GitHub Runner deployment..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Error: Terraform is not installed!"
    exit 1
fi

echo "🔧 Initializing Terraform..."
terraform init

echo "🔍 Planning deployment..."
terraform plan

echo "🏗️  Deploying infrastructure..."
terraform apply -auto-approve

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Server Information:"
terraform output -json | jq -r '
  "Server ID: " + .server_id.value + "\n" +
  "Server Name: " + .server_name.value + "\n" +
  "Public IP: " + .server_public_ip.value + "\n" +
  "SSH Connection: " + .ssh_connection.value + "\n" +
  "Status: " + .server_status.value
'

echo ""
echo "🔗 To connect to your server:"
echo "$(terraform output -raw ssh_connection)"
