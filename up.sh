#!/bin/bash

set -e

echo "🚀 Starting Hetzner Cloud GitHub Runner deployment..."

if ! command -v tofu &> /dev/null; then
    echo "❌ Error: OpenTofu is not installed!"
    exit 1
fi

echo "🔧 Initializing OpenTofu..."
tofu init

echo "🔍 Planning deployment..."
tofu plan

echo "🏗️  Deploying infrastructure..."
tofu apply -auto-approve

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Server Information:"
tofu output -json | jq -r '
  "Server ID: " + .server_id.value + "\n" +
  "Server Name: " + .server_name.value + "\n" +
  "Public IP: " + .server_public_ip.value + "\n" +
  "SSH Connection: " + .ssh_connection.value + "\n" +
  "Status: " + .server_status.value
'

echo ""
echo "🔗 To connect to your server:"
echo "$(tofu output -raw ssh_connection)"
