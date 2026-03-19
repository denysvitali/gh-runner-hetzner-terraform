variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "server_name" {
  description = "Name of the server"
  type        = string
  default     = "gh-runner"
}

variable "server_image" {
  description = "Server image to use"
  type        = string
  default     = "ubuntu-24.04"
}

variable "server_location" {
  description = "Server location"
  type        = string
  default     = "nbg1"
}

variable "server_type" {
  description = "Server Type"
  type = string
  default = "cax21" # ARM64 4vCPU 8GB RAM, see https://www.hetzner.com/cloud/#pricing
}

variable "repo" {
  description = "GitHub Repository"
  default = "denysvitali/linux-surface"
}

variable "runner_version" {
  description = "GitHub Runner Version"
  type = string
  default = "2.332.0"
}

variable "runner_sha256" {
  type = string
  default = "b72f0599cdbd99dd9513ab64fcb59e424fc7359c93b849e8f5efdd5a72f743a6"
}

variable "runner_token" {
  description = "GitHub token - either a Registration Token from the Runner settings page (starts with 'A' followed by alphanumeric chars) or a Personal Access Token (PAT) with 'repo' scope for private repos or 'public_repo' for public repos"
  sensitive = true
}
