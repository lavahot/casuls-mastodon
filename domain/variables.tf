# The domain name is passed in as a variable, and the domain name is used to create the route53 zone and record.

variable "domain_name" {
  type        = string
  description = "The domain name to use for the mastodon instance"
}
