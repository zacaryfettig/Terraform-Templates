resource "aws_ecr_repository" "messageapp" {
  name                 = "messagingappregistry/messageapp"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_repository" "psql" {
  name                 = "messagingappregistry/psql"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}



/*
resource "local_file" "ecrOutput" {
    content  = aws_ecr_repository.registry2.repository_url
    filename = "ecrOutput.txt"
}


resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.application.id
  service_name        = "com.amazonaws.us-west-2.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [aws_security_group.ecsSecurityGroup]

    subnet_ids = [
    aws_subnet.containerSubnet1, aws_subnet.containerSubnet2
  ]

  subnet_configuration {
    ipv4      = "10.0.1.10"
    subnet_id = aws_subnet.containerSubnet1
  }
  subnet_configuration {
    ipv4      = "10.0.2.10"
    subnet_id = aws_subnet.containerSubnet2
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.application.id
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = aws_route_table.routeTable.id

    subnet_ids = [
    aws_subnet.containerSubnet1, aws_subnet.containerSubnet2
  ]

}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.application.id
  service_name        = "com.amazonaws.us-west-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [aws_security_group.vpc_endpoints.id]

    subnet_ids = [
    aws_subnet.containerSubnet1, aws_subnet.containerSubnet2
  ]
}
*/