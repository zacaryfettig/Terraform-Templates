#bitwarden networking
resource "aws_vpc" "application" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "containerSubnet1" {
    vpc_id = aws_vpc.application.id
    cidr_block = "10.0.1.0/24"
    availability_zone = var.az1
    map_public_ip_on_launch = true
}

resource "aws_subnet" "containerSubnet2" {
    vpc_id = aws_vpc.application.id
    cidr_block = "10.0.2.0/24"
    availability_zone = var.az2
    map_public_ip_on_launch = true
}

resource "aws_subnet" "databaseSubnet1" {
    vpc_id = aws_vpc.application.id
    cidr_block = "10.0.3.0/24"
    availability_zone = var.az1
    map_public_ip_on_launch = true
}

resource "aws_subnet" "databaseSubnet2" {
    vpc_id = aws_vpc.application.id
    cidr_block = "10.0.4.0/24"
    availability_zone = var.az2
    map_public_ip_on_launch = true
}


resource "aws_internet_gateway" "applicationInternetGateway" {
  vpc_id = aws_vpc.application.id
}

resource "aws_route_table" "routeTable" {
  vpc_id = aws_vpc.application.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.applicationInternetGateway.id
  }
}

resource "aws_route_table_association" "routeTableAssociation1" {
    route_table_id = aws_route_table.routeTable.id
    subnet_id = aws_subnet.containerSubnet1.id
}

resource "aws_route_table_association" "routeTableAssociation2" {
    route_table_id = aws_route_table.routeTable.id
    subnet_id = aws_subnet.containerSubnet2.id
}

resource "aws_route_table_association" "routeTableAssociation3" {
    route_table_id = aws_route_table.routeTable.id
    subnet_id = aws_subnet.databaseSubnet1.id
}

resource "aws_route_table_association" "routeTableAssociation4" {
    route_table_id = aws_route_table.routeTable.id
    subnet_id = aws_subnet.databaseSubnet2.id
}

resource "aws_eip" "eipNat" {
  domain = "vpc"
}

resource "aws_security_group" "bastionSG" {
    name = "bastionSecurityGroup"
    vpc_id = aws_vpc.application.id
}

resource "aws_security_group_rule" "sshInbound" {
type = "ingress"
from_port = "22"
to_port = "22"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
security_group_id = aws_security_group.bastionSG.id
}

resource "aws_security_group_rule" "downloads" {
    type = "egress"
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    security_group_id = aws_security_group.bastionSG.id
  
}

resource "aws_lb_target_group" "ecs_tg" {
 name        = "ecs-target-group"
 port        = 80
 protocol    = "HTTP"
 target_type = "ip"
 vpc_id      = aws_vpc.application.id

 health_check {
   path = "/"
 }
}

resource "aws_route53_zone" "privateDNS" {
  name = "messagingapp.com"
  vpc {
    vpc_id = aws_vpc.application.id
  }
}

resource "aws_route53_record" "database" {
  zone_id = "${aws_route53_zone.privateDNS.zone_id}"
  name = "database.messagingapp.com"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_db_instance.rds.address}"]
}
