
resource "aws_db_subnet_group" "databaseSubnetGroup" {
name = "databasesubnetgroup"
subnet_ids = [aws_subnet.databaseSubnet1.id, aws_subnet.databaseSubnet2.id]
}

resource "aws_db_instance" "rds" {
  allocated_storage = 200
  auto_minor_version_upgrade = false
  backup_retention_period = 7
  db_subnet_group_name = aws_db_subnet_group.databaseSubnetGroup.name
  engine = "postgres"
  engine_version = "16.3"
  identifier = "postgres"
  instance_class = "db.t3.micro"
  multi_az = true
  password = "5J$&56U-cO"
  storage_encrypted = false
  username = "postgresadmin"
  db_name = "postgres"
  skip_final_snapshot = true
  publicly_accessible = true
  vpc_security_group_ids = [ aws_security_group.databaseSecurityGroup.id ]
  timeouts {
    create = "3h"
    delete = "3h"
    update = "3h"
  }
}

resource "aws_security_group" "databaseSecurityGroup" {
  name        = "databaseSecurityGroup"
  description = "enable database access on port 5432"
  vpc_id      = aws_vpc.application.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
