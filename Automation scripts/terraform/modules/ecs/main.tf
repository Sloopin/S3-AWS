resource "aws_ecs_cluster" "dev_to" {
  name = "Webapp"
  capacity_providers = [
    "FARGATE"]
  setting {
    name = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "Webapp"
    Project = "dev-to"
    Billing = "dev-to"
  }
}

resource "aws_ecs_task_definition" "dev_to" {
  family = "dev-to"
  container_definitions = <<TASK_DEFINITION
  [
  {
    "portMappings": [
      {
        "hostPort": 80,
        "protocol": "tcp",
        "containerPort": 80
      },
      {
        "hostPort": 9100,
        "protocol": "all",
        "containerPort": 9100
      }
    ],
    "cpu": 512,
    "environment": [
      {
        "name": "AUTHOR",
        "value": "Jorn"
      }
    ],
    "memory": 2048,
    "image": "jorb19/webappfix:v2",
    "essential": true,
    "name": "site"
  }
]
TASK_DEFINITION

  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"]
  memory = "8192"
  cpu = "4096"
  execution_role_arn = var.ecs_role.arn
  task_role_arn = var.ecs_role.arn

  tags = {
    Name = "Webappcs4"
    Project = "dev-to"
    Billing = "dev-to"
  }
}

resource "aws_ecs_service" "dev_to" {
  name = "dev-to"
  cluster = aws_ecs_cluster.dev_to.id
  task_definition = aws_ecs_task_definition.dev_to.arn
  desired_count = 1
  launch_type = "FARGATE"
  platform_version = "1.4.0"

  lifecycle {
    ignore_changes = [
      desired_count]
  }

  network_configuration {
    subnets = [
      var.ecs_subnet_a.id,
      var.ecs_subnet_b.id,
      var.ecs_subnet_c.id]
    security_groups = [
      var.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.ecs_target_group.arn
    container_name = "site"
    container_port = 80
  }
}
