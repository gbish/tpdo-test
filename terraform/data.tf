# Retrieve the task definition so it can be used in comparison
data "aws_ecs_task_definition" "hello_world" {
  task_definition = aws_ecs_task_definition.hello_world.family
}

# Retrieve the exsiting role by name for use in ECS
data "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskExecutionRole"
}
