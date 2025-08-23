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
  default = "cax31" # ARM64, see https://www.hetzner.com/cloud/#pricing
}

variable "repo" {
  description = "GitHub Repository"
  default = "denysvitali/omarchy-chromium"
}

variable "runner_version" {
  description = "GitHub Runner Version"
  type = string
  default = "2.328.0"
}

variable "runner_sha256" {
  type = string
  default = "b801b9809c4d9301932bccadf57ca13533073b2aa9fa9b8e625a8db905b5d8eb"
}

variable "runner_token" {
  description = "GitHub Runner Token"
  sensitive = true
}
