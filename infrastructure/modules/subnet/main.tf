# Generic subnet module. Routing, gateway, and public/private semantics are handled in the region VPC file.
# Subnets created from the supplied CIDR and availability-zone lists.
resource "aws_subnet" "subnet" {
  count                   = length(var.subnet_cidrs)
  vpc_id                  = var.vpc_id
  cidr_block              = var.subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name         = "${var.project}-${var.name_prefix}-${count.index + 1}"
    Owner        = var.owner
    Project      = var.project
    Environment  = var.environment
    "aws-apn-id" = var.aws_apn_id
  }
}
