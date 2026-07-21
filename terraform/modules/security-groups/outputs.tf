output "cluster_sg" {
  value = aws_security_group.cluster.id
}

output "node_sg" {
  value = aws_security_group.nodes.id
}