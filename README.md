# casuls-mastodon

The mastodon deployment repo for casuls.social

This repo contains the entire deployment for the casuls.social mastodon site.

## Requirements for Masto-cluster module

1. An existing domain set up on Route53
2. The following IAM permissions are required for the Terraform user:
   1.

## Deploying the Masto-cluster module

To deploy, due to Terraform constraints, you must deploy the vpc first:

`terraform apply -target module.vpc`

Then deploy the rest:

`terraform apply - target module.vpc`
