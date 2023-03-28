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

module "domain" {
  source      = "./domain"
  domain_name = local.domain_name
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "mastodon_cluster" {
  source = "./masto-cluster"

  # VPC information
  vpc_id                        = module.vpc.vpc_id
  private_subnet_ids            = module.vpc.private_subnets
  public_subnet_ids             = module.vpc.public_subnets
  vpc_cidr_block                = module.vpc.vpc_cidr_block
  rds_subnet_group_name         = module.vpc.database_subnet_group_name
  elasticache_subnet_group_name = module.vpc.elasticache_subnet_group_name

  # Domain information
  domain_name = local.domain_name
  zone_id     = module.domain.zone_id

  # Certificate information
  certificate_arn = aws_acm_certificate_validation.mastodon.certificate_arn
}


# Create an alias record for the load balancer

resource "aws_route53_record" "mastodon" {
  zone_id = module.domain.zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = module.mastodon_cluster.load_balancer_dns
    zone_id                = module.mastodon_cluster.load_balancer_zone_id
    evaluate_target_health = false
  }
}
