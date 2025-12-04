output "control_plane_nodes_public_ips" {
  description = "The public ip addresses of the talos control plane nodes"
  value       = module.cluster.control_plane_nodes_public_ips
}

output "control_plane_nodes_private_ips" {
  description = "The private ip addresses of the talos control plane nodes"
  value       = module.cluster.control_plane_nodes_private_ips
}

output "backend_ecr_repo" {
  description = "The Backend ECR repository"
  value       = module.cluster.backend_ecr_repo
}
