# casuls-mastodon

The mastodon deployment repo for casuls.social

This repo contains the entire deployment for the casuls.social mastodon site.

## Requirements for Masto-cluster module

1. An existing domain set up on Route53
2. The following IAM permissions are required for the Terraform user:
   1. All of them
3. A VPC
4. An SSL cert in ACM.

## Deploying the Masto-cluster module

`terraform apply`
