# An output for the list of nameservers for the domain

output "nameservers" {
  value = aws_route53_zone.domain.name_servers
}

output "zone_id" {
  value = aws_route53_zone.domain.zone_id
}
