terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

locals {
  project_name = "opensearch-eks"
  opensearch_domain_name = "opensearch-cluster"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name       = local.project_name
  vpc_cidr          = var.vpc_cidr
  environment       = var.environment
  availability_zones = var.availability_zones
}

# OpenSearch Module
module "opensearch" {
  source = "./modules/opensearch"

  domain_name              = local.opensearch_domain_name
  environment             = var.environment
  instance_type           = "t3.small.search"
  instance_count          = 2
  vpc_id                  = module.vpc.vpc_id
  vpc_cidr                = var.vpc_cidr
  private_subnets         = module.vpc.private_subnets
  eks_security_group_id   = module.eks.node_security_group_id
  bastion_security_group_id = module.vpc.bastion_security_group_id
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name              = local.project_name
  vpc_id                    = module.vpc.vpc_id
  private_subnets          = module.vpc.private_subnets
  node_instance_type       = var.node_instance_type
  environment              = var.environment
  bastion_security_group_id = module.vpc.bastion_security_group_id
}

# Add the ingress module
module "ingress" {
  source = "./modules/ingress"
  
  dashboard_domain       = "dashboard.yourdomain.com"  # Replace with your domain
  cluster_name          = module.eks.cluster_name
  vpc_id               = module.vpc.vpc_id
  opensearch_cluster_name = local.opensearch_domain_name

  depends_on = [module.eks, module.opensearch]
}