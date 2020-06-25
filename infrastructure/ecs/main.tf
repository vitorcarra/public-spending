resource "aws_ecs_cluster" "airflow-celery1" {
  name = "airflow-celery1"
  capacity_providers = ["FARGATE"]
}


resource "aws_ecs_task_definition" "webserver" {
  family                = "service"
  #container_definitions = file("${path.module}/task-definitions/webserver.json")
  requires_compatibilities = ["FARGATE"]

  container_definitions = <<TASK_DEFINITION
  [
    {
        "name": "webserver",
        "image": "teste",
        "essential": true,
        "command": ["webserver"],
        "portMappings": [
            {
                "containerPort": 8080,
                "hostPort": 8080
            }
        ],
        "environment": [
            { "name": "POSTGRES_USER", "value": "${var.postgres_user}"},
            { "name": "POSTGRES_PORT", "value": "${var.postgres_port}"},
            { "name": "POSTGRES_HOST", "value": "${var.postgres_host}"},
            { "name": "POSTGRES_DB", "value": "${var.postgres_db}"},
            { "name": "POSTGRES_PASSWORD", "value": "${var.postgres_password}"}
        ]
    }
  ]
  TASK_DEFINITION

  task_role_arn = var.role_ecs_arn
  execution_role_arn = var.role_ecs_arn

  network_mode = "awsvpc"
  cpu = 512
  memory = 1024
}