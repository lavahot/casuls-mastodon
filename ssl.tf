# # Set up SSL through AWS Certificate Manager (ACM)

# Create a new certificate
resource "aws_acm_certificate" "mastodon" {
  domain_name       = local.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create a new record in Route53 to prove we own the domain

resource "aws_route53_record" "mastodon-ssl" {
  for_each = {
    for dvo in aws_acm_certificate.mastodon.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name            = each.value.name
  type            = each.value.type
  zone_id         = module.domain.zone_id
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Wait for Route53 to propagate before requesting validation

resource "aws_acm_certificate_validation" "mastodon" {
  certificate_arn         = aws_acm_certificate.mastodon.arn
  validation_record_fqdns = [for record in aws_route53_record.mastodon-ssl : record.fqdn]
}
