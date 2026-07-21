# Create the Cluster

resource "aws_eks_cluster" "this" {

  name = "${var.project_name}-cluster"

  role_arn = var.cluster_role_arn

  version = "1.32"

  vpc_config {

    subnet_ids = var.private_subnets

    security_group_ids = [
      var.cluster_sg
    ]

    endpoint_private_access = true

    endpoint_public_access = true

  }

  depends_on = [
    var.cluster_role_arn
  ]
}

# Create the Managed Node Group

resource "aws_eks_node_group" "main" {

  cluster_name    = aws_eks_cluster.this.name

  node_group_name = "${var.project_name}-node-group"

  node_role_arn   = var.node_role_arn

  subnet_ids      = var.private_subnets

  instance_types = var.instance_types

  capacity_type = "ON_DEMAND"

  scaling_config {

    desired_size = 2

    max_size = 3

    min_size = 2

  }

  ami_type = var.ami_type

  disk_size = 20

}