# Private link between this region's VPC and the shared database VPC (us-east-1).
# The VPCs are in different regions, so this side requests the connection and the
# us-east-1 side (provider aws.data) accepts it.
# Destroying this region removes the peering connection and both routes with it.
resource "aws_vpc_peering_connection" "data" {
  vpc_id      = aws_vpc.main.id
  peer_vpc_id = data.terraform_remote_state.data.outputs.vpc_id
  peer_region = "us-east-1"

  tags = merge(local.tags, {
    Name = "${local.project}-to-shared-data"
  })
}

resource "aws_vpc_peering_connection_accepter" "data" {
  provider                  = aws.data
  vpc_peering_connection_id = aws_vpc_peering_connection.data.id
  auto_accept               = true

  tags = merge(local.tags, {
    Name = "${local.project}-to-shared-data"
  })
}

# Lets this VPC resolve the database hostname to its private address through the peering.
resource "aws_vpc_peering_connection_options" "data" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.data.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

# This region -> database VPC.
resource "aws_route" "to_data" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.terraform_remote_state.data.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.data.id
}

# Database VPC -> this region (return path for the answers). Created in us-east-1.
resource "aws_route" "from_data" {
  provider                  = aws.data
  route_table_id            = data.terraform_remote_state.data.outputs.private_route_table_id
  destination_cidr_block    = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.data.id
}