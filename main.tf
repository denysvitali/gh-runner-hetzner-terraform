
resource "hcloud_ssh_key" "gh_key" {
  name = "gh_key_${each.key}"
  public_key = each.value
  for_each = toset(compact(split("\n", data.http.ssh_key.response_body)))
}

data "http" "ssh_key" {
  url = "https://github.com/${split("/", var.repo)[0]}.keys"
  request_headers = {
    "Accept": "text/html"
  }
}

resource "hcloud_server" "gh_runner" {
  name        = var.server_name
  image       = var.server_image
  server_type = var.server_type
  location    = var.server_location
  ssh_keys    = [for key in hcloud_ssh_key.gh_key : key.id]
  
  user_data = templatefile("${path.module}/scripts/start.sh", {
    RUNNER_VERSION = var.runner_version
    RUNNER_TOKEN = var.runner_token
    RUNNER_SHA256 = var.runner_sha256
    REPO = var.repo
  })

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  labels = {
    purpose = "github-runner"
    managed = "terraform"
  }

  lifecycle {
    prevent_destroy = false
    precondition {
      condition = contains([200], data.http.ssh_key.status_code)
      error_message = "Invalid status code"
    }
  }
}

resource "hcloud_firewall" "gh_runner" {
  name = "${var.server_name}-firewall"
  
  rule {
    direction = "in"
    source_ips = ["0.0.0.0/0", "::/0"]
    port = "22"
    protocol = "tcp"
  }
  
}

resource "hcloud_firewall_attachment" "gh_runner" {
  firewall_id = hcloud_firewall.gh_runner.id
  server_ids  = [hcloud_server.gh_runner.id]
}
