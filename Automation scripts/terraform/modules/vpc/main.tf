resource "aws_vpc" "vpc-web" {
  cidr_block = "192.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-web"
    Project = "dev-to"
  }
}

resource "aws_vpc" "vpc-backend" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-backend"
    Project = "dev-to"
  }
}

resource "aws_internet_gateway" "internal_gateway" {
  vpc_id = aws_vpc.vpc-web.id
  tags = {
    Name = "IGW-webvpc"
    Project = "dev-to"
    Billing = "dev-to"
  }
}

resource "aws_internet_gateway" "backend_gateway" {
  vpc_id = aws_vpc.vpc-backend.id
  tags = {
    Name = "IGW-backendvpc"
    Project = "dev-to"
    Billing = "dev-to"
  }
}

resource "aws_route_table" "route_table_web" {
  vpc_id = aws_vpc.vpc-web.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internal_gateway.id
  }

  tags = {
    Name = "RTweb-vpc"
    Project = "dev-to"
  }
}

resource "aws_route_table" "route_table_backend" {
  vpc_id = aws_vpc.vpc-backend.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.backend_gateway.id
  }

  tags = {
    Name = "RTbackend-vpc"
    Project = "dev-to"
  }
}

resource "aws_main_route_table_association" "web" {
  vpc_id         = aws_vpc.vpc-web.id
  route_table_id = aws_route_table.route_table_web.id
}

resource "aws_main_route_table_association" "back" {
  vpc_id         = aws_vpc.vpc-backend.id
  route_table_id = aws_route_table.route_table_backend.id
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "elb_a" {
  vpc_id = aws_vpc.vpc-web.id
  cidr_block = "192.0.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "elb-a"
    Project = "dev-to"
  }
}

resource "aws_subnet" "elb_b" {
  vpc_id = aws_vpc.vpc-web.id
  cidr_block = "192.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "elb-b"
    Project = "dev-to"
  }
}

resource "aws_subnet" "elb_c" {
  vpc_id = aws_vpc.vpc-web.id
  cidr_block = "192.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true
  tags = {
    Name = "elb-c"
    Project = "dev-to"
  }
}

resource "aws_subnet" "ecs_a" {
  vpc_id = aws_vpc.vpc-web.id
  cidr_block = "192.0.3.0/28"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "ecs-a"
    Project = "dev-to"
  }
}

resource "aws_subnet" "ecs_b" {
  vpc_id = aws_vpc.vpc-web.id
  cidr_block = "192.0.4.0/28"
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "ecs-b"
    Project = "dev-to"
  }
}

resource "aws_subnet" "ecs_c" {
  vpc_id = aws_vpc.vpc-web.id
  cidr_block = "192.0.5.0/28"
  availability_zone = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true
  tags = {
    Name = "ecs-c"
    Project = "dev-to"
  }
}

resource "aws_subnet" "PrivSub1" {
  vpc_id = aws_vpc.vpc-backend.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "PrivSub1"
    Project = "dev-to"
  }
}

resource "aws_route_table_association" "elb_a" {
  subnet_id = aws_subnet.elb_a.id
  route_table_id = aws_route_table.route_table_web.id
}

resource "aws_route_table_association" "elb_b" {
  subnet_id = aws_subnet.elb_b.id
  route_table_id = aws_route_table.route_table_web.id
}

resource "aws_route_table_association" "elb_c" {
  subnet_id = aws_subnet.elb_c.id
  route_table_id = aws_route_table.route_table_web.id
}

resource "aws_route_table_association" "ecs_a" {
  subnet_id = aws_subnet.ecs_a.id
  route_table_id = aws_route_table.route_table_web.id
}

resource "aws_route_table_association" "ecs_b" {
  subnet_id = aws_subnet.ecs_b.id
  route_table_id = aws_route_table.route_table_web.id
}

resource "aws_route_table_association" "ecs_c" {
  subnet_id = aws_subnet.ecs_c.id
  route_table_id = aws_route_table.route_table_web.id
}

resource "aws_route_table_association" "PrivSub1" {
  subnet_id = aws_subnet.PrivSub1.id
  route_table_id = aws_route_table.route_table_backend.id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc-web.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "load_balancer" {
  vpc_id = aws_vpc.vpc-web.id
  tags = {
    Name = "load-balancer"
    Project = "dev-to"
  }
}

resource "aws_security_group" "ecs_task" {
  vpc_id = aws_vpc.vpc-web.id
  tags = {
    Name = "ecs-task"
    Project = "dev-to"
  }
}

resource "aws_security_group_rule" "ingress_load_balancer_http" {
  from_port = 80
  protocol = "tcp"
  security_group_id = aws_security_group.load_balancer.id
  to_port = 80
  cidr_blocks = [
    "0.0.0.0/0"]
  type = "ingress"
}

resource "aws_security_group_rule" "p3000loadbalancerin" {
  from_port = 3000
  protocol = "tcp"
  security_group_id = aws_security_group.load_balancer.id
  to_port = 3000
  cidr_blocks = [
    "0.0.0.0/0"]
  type = "ingress"
}

resource "aws_security_group_rule" "p3000loadbalancerout" {
  from_port = 3000
  protocol = "tcp"
  security_group_id = aws_security_group.load_balancer.id
  to_port = 3000
  cidr_blocks = [
    "0.0.0.0/0"]
  type = "egress"
}

resource "aws_security_group_rule" "ingress_load_balancer_https" {
  from_port = 443
  protocol = "tcp"
  security_group_id = aws_security_group.load_balancer.id
  to_port = 443
  cidr_blocks = [
    "0.0.0.0/0"]
  type = "ingress"
}

resource "aws_security_group_rule" "ecs3000out" {
  from_port = 3000
  protocol = "tcp"
  security_group_id = aws_security_group.ecs_task.id
  to_port = 3000
  cidr_blocks = [
    "0.0.0.0/0"]
  type = "egress"
}

resource "aws_security_group_rule" "ecs3000in" {
  from_port = 3000
  protocol = "tcp"
  security_group_id = aws_security_group.ecs_task.id
  to_port = 3000
  cidr_blocks = [
    "0.0.0.0/0"]
  type = "ingress"
}

resource "aws_security_group_rule" "ingress_ecs_task_elb" {
  from_port = 80
  protocol = "tcp"
  security_group_id = aws_security_group.ecs_task.id
  to_port = 80
  source_security_group_id = aws_security_group.load_balancer.id
  type = "ingress"
}

resource "aws_security_group_rule" "egress_load_balancer" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"]
  security_group_id = aws_security_group.load_balancer.id
}

resource "aws_security_group_rule" "egress_ecs_task" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_task.id
}

resource "aws_network_acl" "load_balancer" {
  vpc_id = aws_vpc.vpc-web.id
  subnet_ids = [
    aws_subnet.elb_a.id,
    aws_subnet.elb_b.id,
    aws_subnet.elb_c.id]
}

resource "aws_network_acl" "ecs_task" {
  vpc_id = aws_vpc.vpc-web.id
  subnet_ids = [
    aws_subnet.ecs_a.id,
    aws_subnet.ecs_b.id,
    aws_subnet.ecs_c.id]
}

resource "aws_network_acl_rule" "load_balancer_http" {
  network_acl_id = aws_network_acl.load_balancer.id
  rule_number = 100
  egress = false
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "load_balancer_3000in" {
  network_acl_id = aws_network_acl.load_balancer.id
  rule_number = 1
  egress = true
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 3000
  to_port = 3000
}

resource "aws_network_acl_rule" "load_balancer_3000out" {
  network_acl_id = aws_network_acl.load_balancer.id
  rule_number = 1
  egress = false
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 3000
  to_port = 3000
}

resource "aws_network_acl_rule" "load_balancer_https" {
  network_acl_id = aws_network_acl.load_balancer.id
  rule_number = 200
  egress = false
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

resource "aws_network_acl_rule" "ingress_load_balancer_ephemeral" {
  network_acl_id = aws_network_acl.load_balancer.id
  rule_number = 300
  egress = false
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

resource "aws_network_acl_rule" "ecs_task_300out" {
  network_acl_id = aws_network_acl.ecs_task.id
  rule_number = 1
  egress = true
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 3000
  to_port = 3000
}

resource "aws_network_acl_rule" "ecs_task_300in" {
  network_acl_id = aws_network_acl.ecs_task.id
  rule_number = 1
  egress = false
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 3000
  to_port = 3000
}

resource "aws_network_acl_rule" "ecs_task_ephemeral" {
  network_acl_id = aws_network_acl.ecs_task.id
  rule_number = 100
  egress = false
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

resource "aws_network_acl_rule" "ecs_task_http" {
  network_acl_id = aws_network_acl.ecs_task.id
  rule_number = 200
  egress = false
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = aws_vpc.vpc-web.cidr_block
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "load_balancer_ephemeral" {
  network_acl_id = aws_network_acl.load_balancer.id
  rule_number = 100
  egress = true
  protocol = "tcp"
  rule_action = "allow"
  from_port = 0
  to_port = 65535
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "ecs_task_all" {
  network_acl_id = aws_network_acl.ecs_task.id
  rule_number = 100
  egress = true
  protocol = "tcp"
  rule_action = "allow"
  from_port = 0
  to_port = 65535
  cidr_block = "0.0.0.0/0"
}
