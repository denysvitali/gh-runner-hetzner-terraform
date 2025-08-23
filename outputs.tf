output "server_id" {
  description = "ID of the created server"
  value       = hcloud_server.gh_runner.id
}

output "server_name" {
  description = "Name of the created server"
  value       = hcloud_server.gh_runner.name
}

output "server_public_ip" {
  description = "Public IP address of the server"
  value       = hcloud_server.gh_runner.ipv6_address
}

output "server_status" {
  description = "Status of the server"
  value       = hcloud_server.gh_runner.status
}

output "ssh_connection" {
  description = "SSH connection string"
  value       = "ssh root@${hcloud_server.gh_runner.ipv6_address}"
}
