#!/bin/bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$root_dir/dev"
mkdir -p "$root_dir/modules/vpc"
mkdir -p "$root_dir/modules/security-groups"
mkdir -p "$root_dir/modules/eks"
mkdir -p "$root_dir/modules/iam"
mkdir -p "$root_dir/modules/all"

cat > "$root_dir/dev/main.tf" <<'EOF'
terraform {
  required_version = ">= 1.0.0"
}
EOF

cat > "$root_dir/dev/variables.tf" <<'EOF'
variable "region" {
  type    = string
  default = "us-east-1"
}
EOF

cat > "$root_dir/dev/outputs.tf" <<'EOF'
output "cluster_name" {
  value = ""
}
EOF

cat > "$root_dir/dev/provider.tf" <<'EOF'
provider "aws" {
  region = var.region
}
EOF

cat > "$root_dir/dev/terraform.tf" <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF

cat > "$root_dir/modules/vpc/main.tf" <<'EOF'
resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
}
EOF

cat > "$root_dir/modules/vpc/variables.tf" <<'EOF'
variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}
EOF

cat > "$root_dir/modules/vpc/outputs.tf" <<'EOF'
output "vpc_id" {
  value = aws_vpc.this.id
}
EOF

cat > "$root_dir/modules/security-groups/main.tf" <<'EOF'
resource "aws_security_group" "this" {
  name        = "default"
  description = "Security group created by module"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
EOF

cat > "$root_dir/modules/security-groups/variables.tf" <<'EOF'
variable "vpc_id" {
  type = string
}
EOF

cat > "$root_dir/modules/security-groups/outputs.tf" <<'EOF'
output "security_group_id" {
  value = aws_security_group.this.id
}
EOF

cat > "$root_dir/modules/eks/main.tf" <<'EOF'
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }
}
EOF

cat > "$root_dir/modules/eks/variables.tf" <<'EOF'
variable "cluster_name" {
  type = string
}

variable "cluster_role_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}
EOF

cat > "$root_dir/modules/eks/outputs.tf" <<'EOF'
output "cluster_id" {
  value = aws_eks_cluster.this.id
}
EOF

cat > "$root_dir/modules/iam/main.tf" <<'EOF'
resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = var.assume_role_policy
}
EOF

cat > "$root_dir/modules/iam/variables.tf" <<'EOF'
variable "role_name" {
  type    = string
  default = "eks-role"
}

variable "assume_role_policy" {
  type    = string
  default = "{}"
}
EOF

cat > "$root_dir/modules/iam/outputs.tf" <<'EOF'
output "role_arn" {
  value = aws_iam_role.this.arn
}
EOF


printf "Terraform folder structure created under %s\n" "$root_dir"
