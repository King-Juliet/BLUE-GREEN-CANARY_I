# Global routing layer for cross-region canary
# Route53 weighted routing is used to split traffic between the blue region and green region.
# This can be used as the global canary controller instead of ALB weighted target groups.

resource "aws_route53_zone" "main" {
  name = "example.com"

  tags = {
    Name        = "example-com-zone"
    Owner       = "platform-team"
    Project     = "bluegreen-canary"
    Environment = "shared"
    "aws-apn-id" = "65jiyh5muw5om1whvryxkbpyd"
  }
}

resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  ttl     = 60

  weighted_routing_policy {
    weight = 100
  }

  set_identifier = "blue-region"

  alias {
    name                   = "dualstack.${var.blue_alb_dns_name}"
    zone_id               = var.blue_alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  ttl     = 60

  weighted_routing_policy {
    weight = 0
  }

  set_identifier = "green-region"

  alias {
    name                   = "dualstack.${var.green_alb_dns_name}"
    zone_id               = var.green_alb_zone_id
    evaluate_target_health = true
  }
}
