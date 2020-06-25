resource "aws_ecs_cluster" "airflow-celery1" {
  name = "airflow-celery1"
  capacity_providers = ["FARGATE"]
}


resource "aws_ecs_task_definition" "webserver" {
  family                = "service"
  container_definitions = file("${path.module}/task-definitions/webserver.json")
  requires_compatibilities = ["FARGATE"]

  task_role_arn = var.role_ecs_arn
  execution_role_arn = var.role_ecs_arn

  network_mode = "awsvpc"
  cpu = 512
  memory = 1024
}