provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Name = "MastodonService"
    }
  }
}

locals {
  cluster_name = "casuls-ecs-${random_string.suffix.result}"
  domain_name  = "casuls.social"
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

  vpc_id                        = module.vpc.vpc_id
  private_subnet_ids            = module.vpc.private_subnets
  public_subnet_ids             = module.vpc.public_subnets
  vpc_cidr_block                = module.vpc.vpc_cidr_block
  domain_name                   = local.domain_name
  elasticache_subnet_group_name = module.vpc.elasticache_subnet_group_name
}

}
