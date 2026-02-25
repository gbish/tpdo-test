resource "aws_ecs_cluster" "tpdo" {
  name = var.project_name
}

resource "aws_ecr_repository" "app" {
  name = "${var.project_name}-app"

  force_delete = true
}

# Creates an existing task definition that will get updated via deployments
resource "aws_ecs_task_definition" "hello_world" {
  family                   = "hello-world"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  task_role_arn      = data.aws_iam_role.ecs_task_role.arn
  execution_role_arn = data.aws_iam_role.ecs_task_role.arn

  cpu    = 256
  memory = 512

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "${aws_ecr_repository.app.repository_url}:latest"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])

  # Ignore changes to container definitions so that future updates to Terraform don't overwrite
  # updates made via the deployments from GitHub Actions
  lifecycle {
    ignore_changes = [container_definitions]
  }
}


resource "aws_ecs_service" "service" {
  name    = "${var.project_name}-hello-world"
  cluster = aws_ecs_cluster.tpdo.name
  # Takes the latest task definition
  task_definition                   = "${aws_ecs_task_definition.hello_world.family}:${max(aws_ecs_task_definition.hello_world.revision, data.aws_ecs_task_definition.hello_world.revision)}"
  desired_count                     = 2
  health_check_grace_period_seconds = 60
  launch_type                       = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.hello_world.arn
    container_name   = "app"
    container_port   = 8080
  }

  # Run the tasks in private subnets so they aren't directly exposed to the internet
  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.container.id]
  }
}
