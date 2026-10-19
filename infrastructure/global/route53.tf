# Global DNS layer.
#
# Terraform only owns the hosted zone. The records inside it are owned by the CD pipeline
# (scripts/route53.sh) because they change on every release and depend on which regions exist:
#   app.<zone>          weighted record(s), one per live region, used for the canary split
#   blue.app.<zone>     fixed hostname for the blue region  (used by canary session pinning)
#   green.app.<zone>    fixed hostname for the green region
#
# The first version of this project created the two weighted records here. The "removed" blocks
# below tell Terraform to forget them WITHOUT deleting them, so live traffic is not interrupted.
resource "aws_route53_zone" "main" {
  name = "bluegreen-canary.test"

  tags = {
    Name         = "bluegreen-canary-test-zone"
    Owner        = "platform-team"
    Project      = "bluegreen-canary"
    Environment  = "shared"
    "aws-apn-id" = "65jiyh5muw5om1whvryxkbpyd"
  }
}

removed {
  from = aws_route53_record.blue

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_route53_record.green

  lifecycle {
    destroy = false
  }
}