variable "vpc_id" {
  description = "The id for the VPC to use"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "The IDs for the private subnets"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "The IDs for the public subnets"
  type        = list(string)
  default     = []
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The domain name of the mastodon instance"
  type        = string
  default     = ""
}

variable "elasticache_subnet_group_name" {
  description = "The name of the elasticache subnet group"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "The ARN of the certificate to use for the load balancer"
  type        = string
  default     = ""
}

variable "zone_id" {
  description = "The ID of the zone to use for the domain"
  type        = string
  default     = ""
}
