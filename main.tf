provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "casuls-ecs-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "mastodon_cluster" {
  source = "./masto-cluster"

  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnets[0]
  public_subnet_id  = module.vpc.public_subnets[0]
}
