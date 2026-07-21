resource "aws_security_group" "cluster" {

  name = "${var.project_name}-cluster-sg"

  description = "EKS Cluster"

  vpc_id = var.vpc_id

}

resource "aws_security_group" "nodes" {

  name = "${var.project_name}-node-sg"

  description = "Worker Nodes"

  vpc_id = var.vpc_id

}

resource "aws_security_group_rule" "cluster_ingress" {

  type = "ingress"

  from_port = 443

  to_port = 443

  protocol = "tcp"

  source_security_group_id = aws_security_group.nodes.id

  security_group_id = aws_security_group.cluster.id

}

resource "aws_security_group_rule" "cluster_egress" {

  type = "egress"

  from_port = 0

  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.cluster.id

}


resource "aws_security_group_rule" "node_ingress" {

  type = "ingress"

  from_port = 0

  to_port = 65535

  protocol = "tcp"

  self = true

  security_group_id = aws_security_group.nodes.id

}

resource "aws_security_group_rule" "node_egress" {

  type = "egress"

  from_port = 0

  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.nodes.id

}