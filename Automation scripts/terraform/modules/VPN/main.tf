resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = var.vpcbackend
}

resource "aws_customer_gateway" "customer_gateway" {
  bgp_asn    = 42069
  ip_address = "145.220.75.94"
  type       = "ipsec.1"
}

resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.customer_gateway.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
  Name = "VPN-backend"
  Project = "dev-to"
  }
}

resource "aws_vpn_connection_route" "Infralab" {
  destination_cidr_block = "192.168.1.0/24"
  vpn_connection_id      = aws_vpn_connection.main.id
}