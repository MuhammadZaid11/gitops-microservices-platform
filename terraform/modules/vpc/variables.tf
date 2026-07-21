variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "project_name" {
  type = string
  default = "eks-production-platform"
}

variable "public_subnets" {
  type = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_subnets" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  type = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}