variable "project_name" {}

variable "cluster_role_arn" {}

variable "private_subnets" {
  type = list(string)
}

variable "cluster_sg" {}

variable "cluster_name" {}

variable "node_role_arn" {}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.small"]
  description = "List of instance types for the node group"
}

variable "ami_type" {
  type        = string
  default     = "AL2023_x86_64_STANDARD"
  description = "The AMI type for the node group"
}