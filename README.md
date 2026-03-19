# GitHub Actions Self-Hosted Runner on Hetzner Cloud (ARM64)

This Terraform configuration deploys a self-hosted GitHub Actions runner on Hetzner Cloud using ARM64 servers.

## Prerequisites

1. **Hetzner Cloud Account**: You need a Hetzner Cloud account and API token
2. **GitHub Personal Access Token (PAT)**: Required to register the runner
3. **Terraform**: Install Terraform on your local machine

## Setup Instructions

### 1. Create a GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Required scopes:
   - For **public repositories**: `public_repo`
   - For **private repositories**: `repo` (full control)
   - For **organization runners**: also add `admin:org`
4. Save the token securely

### 2. Create a Hetzner Cloud API Token

1. Log in to [Hetzner Cloud Console](https://console.hetzner.cloud)
2. Select your project or create a new one
3. Go to Security → API tokens
4. Generate a new token with Read & Write permissions
5. Save the token securely

### 3. Configure Terraform Variables

Create a `terraform.tfvars` file with your configuration:

```hcl
hcloud_token  = "your-hetzner-api-token"
runner_token  = "your-github-pat-token"
repo          = "owner/repository"  # e.g., "octocat/hello-world"
server_name   = "gh-runner"         # Optional: custom name for your runner
server_type   = "cax31"             # Optional: ARM64 server type (cax11, cax21, cax31, cax41)
```

### 4. Deploy the Runner

```bash
# Initialize Terraform
terraform init

# Review the planned changes
terraform plan

# Deploy the infrastructure
terraform apply
```

### 5. Verify the Runner

After deployment:
1. Go to your GitHub repository
2. Navigate to Settings → Actions → Runners
3. You should see your new runner listed as "hetzner-runner-[hostname]"

## Configuration Options

| Variable | Description | Default |
|----------|-------------|---------|
| `hcloud_token` | Hetzner Cloud API Token | Required |
| `runner_token` | GitHub Personal Access Token | Required |
| `repo` | GitHub repository (format: `owner/repo`) | `denysvitali/omarchy-chromium` |
| `server_name` | Name of the Hetzner server | `gh-runner` |
| `server_type` | Hetzner server type (ARM64) | `cax31` |
| `server_location` | Hetzner datacenter location | `nbg1` |
| `server_image` | Operating system image | `ubuntu-24.04` |
| `runner_version` | GitHub Actions Runner version | `2.328.0` |

## Available ARM64 Server Types

- `cax11`: 2 vCPU, 4 GB RAM
- `cax21`: 4 vCPU, 8 GB RAM
- `cax31`: 8 vCPU, 16 GB RAM
- `cax41`: 16 vCPU, 32 GB RAM

## Troubleshooting

### Runner Registration Fails

If you see a 404 error during runner registration:
1. Verify your PAT has the correct scopes
2. Check that the repository path is correct
3. Ensure the PAT hasn't expired
4. For organization runners, ensure you have admin permissions

### Checking Runner Status

SSH into the server and check the service:
```bash
ssh root@<server-ip>
systemctl status gh-actions-runner.service
journalctl -u gh-actions-runner.service -f
```

### Manual Runner Configuration

If automatic registration fails, SSH into the server and run:
```bash
# Get a new registration token
REGISTRATION_TOKEN=$(curl -sX POST \
  -H "Authorization: Bearer YOUR_PAT_HERE" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/OWNER/REPO/actions/runners/registration-token" | jq -r '.token')

# Configure the runner
cd /home/runner
sudo -u runner ./config.sh \
  --url "https://github.com/OWNER/REPO" \
  --token "$REGISTRATION_TOKEN" \
  --name "hetzner-runner-$(hostname)" \
  --labels "arm64,linux,hetzner" \
  --unattended \
  --replace
```

## Cleanup

To remove the runner and infrastructure:
```bash
terraform destroy
```

## Security Considerations

1. **Never commit tokens**: Keep your `terraform.tfvars` file out of version control
2. **Use environment variables**: Alternatively, set tokens as environment variables:
   ```bash
   export TF_VAR_hcloud_token="your-token"
   export TF_VAR_runner_token="your-pat"
   ```
3. **Firewall**: Only SSH (port 22) is open by default
4. **Updates**: The runner automatically updates when GitHub releases new versions

## License

MIT