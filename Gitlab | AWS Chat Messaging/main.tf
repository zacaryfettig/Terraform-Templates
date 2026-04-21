data "aws_caller_identity" "current" {}
/*
variable "awsID" {
  description = "AWS Account ID"
  type        = string
  default     = "${data.aws_caller_identity.current.account_id}"
}
*/
locals {
  awsID = data.aws_caller_identity.current.account_id
}

resource "aws_ecs_cluster" "ecsCluster" {
  name = "ecsCluster"
  depends_on = [ aws_db_instance.rds ]

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "ecsService" {
name = "ecsService"
launch_type = "FARGATE"
platform_version = "LATEST"
cluster = aws_ecs_cluster.ecsCluster.id
task_definition = aws_ecs_task_definition.ecsTaskDefinition.arn
scheduling_strategy = "REPLICA"
desired_count = 1
deployment_minimum_healthy_percent = 100
deployment_maximum_percent = 200
//iam_role = aws_iam_role.ecsRole.arn
// = [ aws_iam_role.ecsRole ]
depends_on = [ aws_db_instance.rds, aws_lb.ecsLB, aws_lb_listener.ecsLbListener, aws_route53_record.database, aws_route53_zone.privateDNS, aws_security_group.databaseSecurityGroup ]

load_balancer {
  target_group_arn = aws_lb_target_group.lbTargetGroup.arn
  container_name = "messageApplication"
  container_port = 5000
}

network_configuration {
  assign_public_ip = true
  security_groups = [ aws_security_group.ecsSecurityGroup.id ]
  subnets = [aws_subnet.containerSubnet1.id, aws_subnet.containerSubnet2.id]
}
}
/*
data "aws_ecr_image" "ecrImage" {
  repository_name = "registry1/messageapp"
  most_recent = true
}
*/
resource "aws_ecs_task_definition" "ecsTaskDefinition" {
  family = "messageApplication"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = aws_iam_role.ecsRole.arn
  network_mode = "awsvpc"
  cpu = 1024
  memory = 2048
  depends_on = [ aws_db_instance.rds ]
  container_definitions = jsonencode( [
    {
    name = "messageApplication"
    image = "${local.awsID}.dkr.ecr.us-west-2.amazonaws.com/messagingappregistry/messageapp:latest"
    cpu = 1024
    memory = 2048
    essential = true
    portMappings = [
        {
            containerPort = 5000
            hostPort = 5000
        }
    ]
    }
  ])
  }

resource "aws_lb" "ecsLB" {
  name               = "ecsLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecsSecurityGroup.id]
  subnets            = [aws_subnet.containerSubnet1.id, aws_subnet.containerSubnet2.id]
  enable_deletion_protection = false
  depends_on = [ aws_db_instance.rds ]
/*
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "ecsLB"
    enabled = true
  }
  */
}

resource "aws_security_group" "lbSecurityGroup" {
  name        = "lbSecurityGroup"
  description = "load balancer security group"
  vpc_id      = aws_vpc.application.id
  depends_on = [ aws_db_instance.rds ]

  ingress {
    from_port   = 5000
    to_port     = 5000
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

resource "aws_lb_listener" "ecsLbListener" {
    load_balancer_arn = aws_lb.ecsLB.arn
    port = "5000"
    protocol = "HTTP"
    depends_on = [ aws_db_instance.rds ]

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.lbTargetGroup.arn
    }
}

resource "aws_lb_target_group" "lbTargetGroup" {
  name = "lbTargetGroup"
  port = 5000
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = aws_vpc.application.id
  depends_on = [ aws_db_instance.rds ]
}

#variable "sg_ingress_rules" {
#    type = list(object({
#      from_port   = number
#      to_port     = number
#      protocol    = string
#      cidr_block  = string
#      description = string
#    }))
#    default     = [
#        {
#          from_port   = 80
#          to_port     = 80
#          protocol    = "tcp"
#          cidr_block  = "1.2.3.4/32"
#          description = "test"
#        },
#        {
#          from_port   = 3306
#          to_port     = 3306
#          protocol    = "tcp"
#          cidr_block  = "1.2.3.4/32"
#          description = "test"
#        },
#    ]
#}

resource "aws_security_group" "ecsSecurityGroup" {
  name        = "ecsSecurityGroup"
  description = "elastic container services security group"
  vpc_id      = aws_vpc.application.id
  depends_on = [ aws_db_instance.rds ]

  ingress {
    from_port   = 5000
    to_port     = 5000
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

resource "aws_iam_role_policy" "ecsPolicy" {
  name = "ecsPolicy"
  role = aws_iam_role.ecsRole.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCeckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:CreateLogStream",
          "ecr:PutLogEvents",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ecs:ExecuteCommand",
          "*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "ecsRole" {
  name = "ecsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

