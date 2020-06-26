resource "aws_ecs_cluster" "airflow_celery1" {
  name = "airflow-celery1"
  capacity_providers = ["FARGATE"]

  tags = {
    Project = var.project_name
  }
}


resource "aws_ecs_task_definition" "webserver" {
  family                = "webserver"
  #container_definitions = file("${path.module}/task-definitions/webserver.json")
  requires_compatibilities = ["FARGATE"]

  container_definitions = <<TASK_DEFINITION
  [
    {
        "name": "webserver",
        "image": "${var.docker_image}",
        "essential": true,
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-create-group": "true",
                "awslogs-group": "ecs-airflow",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "airflow-werbserver"
            }
        },
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


resource "aws_ecs_service" "webserver" {
  name            = "webserver"
  cluster         = aws_ecs_cluster.airflow_celery1.id
  task_definition = aws_ecs_task_definition.webserver.arn
  desired_count   = 1
  launch_type = "FARGATE"

  #depends_on      = ["aws_iam_role_policy.foo"]

  network_configuration {
    assign_public_ip = false
    subnets = [var.private_subnet_group_id1, var.private_subnet_group_id2]
    security_groups = var.webserver_sg
  }
}
