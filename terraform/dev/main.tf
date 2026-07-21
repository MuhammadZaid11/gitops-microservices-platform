module "vpc" {

  source = "../modules/vpc"

}

module "iam" {

  source = "../modules/iam"

  project_name = "eks-platform"

}

module "security_groups" {

  source = "../modules/security-groups"

  project_name = "eks-platform"

  vpc_id = module.vpc.vpc_id

}





module "eks" {

  source = "../modules/eks"

  project_name = "eks-platform"

  cluster_name = "eks-platform-cluster"

  cluster_role_arn = module.iam.cluster_role_arn

  node_role_arn = module.iam.node_role_arn

  private_subnets = module.vpc.private_subnets

  cluster_sg = module.security_groups.cluster_sg

}

module "github_oidc" {

  source = "../modules/github-oidc"


}

module "ecr_backend" {
  source    = "../modules/ecr"
  repo_name = "mern-backend"
}

module "ecr_frontend" {
  source    = "../modules/ecr"
  repo_name = "mern-frontend"
}