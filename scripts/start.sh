#!/bin/bash
set -e

# Create a dedicated user for the runner
useradd -m -s /bin/bash runner || true
usermod -aG sudo runner

# Install dependencies
apt-get update
apt-get install -y curl wget git jq libicu-dev

# Switch to runner user home directory
cd /home/runner

# Download and extract the runner
curl -o actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz -L \
  https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

echo "${RUNNER_SHA256}  actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz" | shasum -a 256 -c

tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz
rm actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

# Set proper ownership
chown -R runner:runner /home/runner

# Configure the runner as the runner user
sudo -u runner ./config.sh \
  --url "https://github.com/${REPO}" \
  --token "${RUNNER_TOKEN}" \
  --name "hetzner-runner-$(hostname)" \
  --work "_work" \
  --labels "arm64,linux,hetzner" \
  --unattended \
  --replace

# Create systemd service
cat > /etc/systemd/system/gh-actions-runner.service << EOF
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
Type=simple
User=runner
WorkingDirectory=/home/runner
ExecStart=/home/runner/run.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the service
systemctl daemon-reload
systemctl enable gh-actions-runner.service
systemctl start gh-actions-runner.service

# Check the service status
systemctl status gh-actions-runner.service --no-pager