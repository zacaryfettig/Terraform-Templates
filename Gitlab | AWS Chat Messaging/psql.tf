resource "aws_ecs_service" "ecsServicepsql" {
name = "ecsServicepsql"
launch_type = "FARGATE"
platform_version = "LATEST"
cluster = aws_ecs_cluster.ecsCluster.id
task_definition = aws_ecs_task_definition.ecsTaskDefinitionpsql.arn
scheduling_strategy = "REPLICA"
desired_count = 1
deployment_minimum_healthy_percent = 100
deployment_maximum_percent = 200
enable_execute_command = true
depends_on = [ aws_iam_role.ecsRole ]
network_configuration {
  assign_public_ip = true
  security_groups = [ aws_security_group.ecsSecurityGroup.id ]
  subnets = [aws_subnet.containerSubnet1.id, aws_subnet.containerSubnet2.id]
}
}

resource "aws_ecs_task_definition" "ecsTaskDefinitionpsql" {
  family = "psql"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = aws_iam_role.ecsRole.arn
  task_role_arn = aws_iam_role.ecsRole.arn
  network_mode = "awsvpc"
  cpu = 1024
  memory = 2048
  depends_on = [ aws_db_instance.rds, aws_route53_zone.privateDNS, aws_iam_role_policy.ecsPolicy]
  container_definitions = jsonencode( [
    {
    name = "psql"
    image = "${local.awsID}.dkr.ecr.us-west-2.amazonaws.com/messagingappregistry/psql:latest"
    cpu = 1024
    memory = 1024
    essential = true
    portMappings = [
        {
            containerPort = 22
            hostPort = 22
        }
    ]
    }
  ])
  }

