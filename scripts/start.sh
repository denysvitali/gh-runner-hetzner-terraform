#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "$${GREEN}Starting GitHub Runner setup...$${NC}"

# Create a dedicated user for the runner
echo -e "$$4{GREEN}Creating runner user...$${NC}"
useradd -m -s /bin/bash runner || true
usermod -aG sudo runner

# Install dependencies
echo -e "$${GREEN}Installing dependencies...$${NC}"
apt-get update
apt-get install -y \
  curl \
  wget \
  git \
  jq \
  libicu-dev \
  makepkg \
  fakeroot \
  docker.io


# Install GH CLI
echo -e "$${GREEN}Installing GitHub CLI...$${NC}"
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y

# Switch to runner user home directory
cd /home/runner

# Download and extract the runner
echo -e "$${GREEN}Downloading GitHub Actions Runner v${RUNNER_VERSION}...$${NC}"
curl -o actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz -L \
  https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

echo -e "$${GREEN}Verifying checksum...$${NC}"
echo "${RUNNER_SHA256}  actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz" | shasum -a 256 -c

echo -e "$${GREEN}Extracting runner...$${NC}"
tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz
rm actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

# Set proper ownership
chown -R runner:runner /home/runner

# Determine token type and get registration token
echo -e "$${GREEN}Checking token type...$${NC}"

# Check if the token starts with patterns typical of registration tokens
if [[ "${RUNNER_TOKEN}" =~ ^A[A-Z0-9]{4} ]]; then
  echo -e "$${GREEN}Detected registration token format - using directly$${NC}"
  REGISTRATION_TOKEN="${RUNNER_TOKEN}"
else
  echo -e "$${GREEN}Detected PAT format - fetching registration token from GitHub API...$${NC}"
  REGISTRATION_TOKEN=$(curl -sX POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${RUNNER_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}/actions/runners/registration-token" | jq -r '.token')

  if [ -z "$REGISTRATION_TOKEN" ] || [ "$REGISTRATION_TOKEN" = "null" ]; then
    echo -e "$${RED}Failed to get registration token from GitHub API$${NC}"
    echo -e "$${RED}Please ensure:$${NC}"
    echo -e "$${RED}1. RUNNER_TOKEN is a valid GitHub Personal Access Token (PAT)$${NC}"
    echo -e "$${RED}2. The PAT has 'repo' scope for private repos or 'public_repo' for public repos$${NC}"
    echo -e "$${RED}3. The PAT has 'admin:org' scope if registering for an organization$${NC}"
    echo -e "$${RED}4. The repository path '${REPO}' is correct$${NC}"
    echo -e "$${RED}Or use a registration token directly from GitHub's Runner settings page$${NC}"
    exit 1
  fi
  
  echo -e "$${GREEN}Successfully obtained registration token from API$${NC}"
fi

# Configure the runner as the runner user
echo -e "$${GREEN}Configuring runner...$${NC}"
sudo -u runner ./config.sh \
  --url "https://github.com/${REPO}" \
  --token "$${REGISTRATION_TOKEN}" \
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

usermod -a -G docker runner

# Reload systemd and start the service
systemctl daemon-reload
systemctl enable --now docker
systemctl enable gh-actions-runner.service
systemctl start gh-actions-runner.service

# Check the service status
systemctl status gh-actions-runner.service --no-pager
