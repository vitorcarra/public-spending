resource "aws_ecs_cluster" "airflow_celery1" {
  name = "airflow-celery1"
  capacity_providers = ["FARGATE"]

  tags = {
    Project = var.project_name
  }
}


############ WEBSERVER #################
resource "aws_ecs_task_definition" "webserver" {
  family                = "webserver"
  #container_definitions = file("${path.module}/task-definitions/webserver.json")
  requires_compatibilities = ["FARGATE"]

  container_definitions = <<TASK_DEFINITION
  [
    {
        "name": "webserver",
        "image": "${var.docker_image_airflow}",
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
        "mountPoints": [
          {
              "containerPath": "./airflow/dags",
              "sourceVolume": "airflow-dags-efs"
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

  volume {
    name = "airflow-dags-efs"

    efs_volume_configuration {
      file_system_id          = var.airflow_efs_id
      root_directory          = "/"
    }
  }

  task_role_arn = var.role_ecs_arn
  execution_role_arn = var.role_ecs_arn

  network_mode = "awsvpc"
  cpu = 512
  memory = 1024
}

resource "aws_ecs_service" "webserver" {
  name            = "webserver"
  platform_version = "1.4.0"
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

  load_balancer {
    target_group_arn = var.alb_webserver_target_group
    container_name   = "webserver"
    container_port   = 8080
  }

}

############ REDIS #################
resource "aws_ecs_task_definition" "redis" {
  family                = "redis"
  #container_definitions = file("${path.module}/task-definitions/webserver.json")
  requires_compatibilities = ["FARGATE"]

  container_definitions = <<TASK_DEFINITION
  [
    {
        "name": "redis",
        "image": "${var.docker_image_redis}",
        "essential": true,
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-create-group": "true",
                "awslogs-group": "ecs-airflow",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "airflow-redis"
            }
        },
        "portMappings": [
            {
                "containerPort": 6379,
                "hostPort": 6379
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
  cpu = 1024
  memory = 2048
}

resource "aws_ecs_service" "redis" {
  name            = "redis"
  cluster         = aws_ecs_cluster.airflow_celery1.id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = 1
  launch_type = "FARGATE"

  #depends_on      = ["aws_iam_role_policy.foo"]

  network_configuration {
    assign_public_ip = false
    subnets = [var.private_subnet_group_id1, var.private_subnet_group_id2]
    security_groups = var.redis_sg
  }

  load_balancer {
    target_group_arn = var.alb_redis_target_group
    container_name   = "redis"
    container_port   = 6379
  }
}


############ Scheduler #################
resource "aws_ecs_task_definition" "scheduler" {
  family                = "scheduler"
  #container_definitions = file("${path.module}/task-definitions/webserver.json")
  requires_compatibilities = ["FARGATE"]

  container_definitions = <<TASK_DEFINITION
  [
    {
        "name": "scheduler",
        "image": "${var.docker_image_airflow}",
        "essential": true,
        "command": ["scheduler"],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-create-group": "true",
                "awslogs-group": "ecs-airflow",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "airflow-scheduler"
            }
        },
        "environment": [
            { "name": "POSTGRES_USER", "value": "${var.postgres_user}"},
            { "name": "POSTGRES_PORT", "value": "${var.postgres_port}"},
            { "name": "POSTGRES_HOST", "value": "${var.postgres_host}"},
            { "name": "POSTGRES_DB", "value": "${var.postgres_db}"},
            { "name": "POSTGRES_PASSWORD", "value": "${var.postgres_password}"},
            { "name": "EXECUTOR", "value": "Celery"},
            { "name": "LOAD_EX", "value": "n"},
            { "name": "REDIS_HOST", "value": "${var.redis_host}"}
        ]
    }
  ]
  TASK_DEFINITION

  task_role_arn = var.role_ecs_arn
  execution_role_arn = var.role_ecs_arn

  network_mode = "awsvpc"
  cpu = 1024
  memory = 2048
}

resource "aws_ecs_service" "scheduler" {
  name            = "scheduler"
  cluster         = aws_ecs_cluster.airflow_celery1.id
  task_definition = aws_ecs_task_definition.scheduler.arn
  desired_count   = 1
  launch_type = "FARGATE"

  #depends_on      = ["aws_iam_role_policy.foo"]

  network_configuration {
    assign_public_ip = false
    subnets = [var.private_subnet_group_id1, var.private_subnet_group_id2]
    security_groups = var.scheduler_sg
  }
}


############ Flower #################
resource "aws_ecs_task_definition" "flower" {
  family                = "flower"
  #container_definitions = file("${path.module}/task-definitions/webserver.json")
  requires_compatibilities = ["FARGATE"]

  container_definitions = <<TASK_DEFINITION
  [
    {
        "name": "flower",
        "image": "${var.docker_image_airflow}",
        "essential": true,
        "command": ["flower"],
        "portMappings": [
          {
              "containerPort": 5555,
              "hostPort": 5555
          }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-create-group": "true",
                "awslogs-group": "ecs-airflow",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "airflow-flower"
            }
        },
        "environment": [
            { "name": "REDIS_HOST", "value": "${var.redis_host}"}
        ]
    }
  ]
  TASK_DEFINITION

  task_role_arn = var.role_ecs_arn
  execution_role_arn = var.role_ecs_arn

  network_mode = "awsvpc"
  cpu = 1024
  memory = 2048
}

resource "aws_ecs_service" "flower" {
  name            = "flower"
  cluster         = aws_ecs_cluster.airflow_celery1.id
  task_definition = aws_ecs_task_definition.flower.arn
  desired_count   = 1
  launch_type = "FARGATE"

  #depends_on      = ["aws_iam_role_policy.foo"]

  network_configuration {
    assign_public_ip = false
    subnets = [var.private_subnet_group_id1, var.private_subnet_group_id2]
    security_groups = var.flower_sg
  }
}

############ Worker #################
resource "aws_ecs_task_definition" "worker" {
  family                = "worker"
  #container_definitions = file("${path.module}/task-definitions/webserver.json")
  requires_compatibilities = ["FARGATE"]

  container_definitions = <<TASK_DEFINITION
  [
    {
        "name": "worker",
        "image": "${var.docker_image_airflow}",
        "essential": true,
        "command": ["worker"],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-create-group": "true",
                "awslogs-group": "ecs-airflow",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "airflow-worker"
            }
        },
        "environment": [
            { "name": "POSTGRES_USER", "value": "${var.postgres_user}"},
            { "name": "POSTGRES_PORT", "value": "${var.postgres_port}"},
            { "name": "POSTGRES_HOST", "value": "${var.postgres_host}"},
            { "name": "POSTGRES_DB", "value": "${var.postgres_db}"},
            { "name": "POSTGRES_PASSWORD", "value": "${var.postgres_password}"},
            { "name": "REDIS_HOST", "value": "${var.redis_host}"}
        ]
    }
  ]
  TASK_DEFINITION

  task_role_arn = var.role_ecs_arn
  execution_role_arn = var.role_ecs_arn

  network_mode = "awsvpc"
  cpu = 1024
  memory = 2048
}

resource "aws_ecs_service" "worker" {
  name            = "worker"
  cluster         = aws_ecs_cluster.airflow_celery1.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1
  launch_type = "FARGATE"

  #depends_on      = ["aws_iam_role_policy.foo"]

  network_configuration {
    assign_public_ip = false
    subnets = [var.private_subnet_group_id1, var.private_subnet_group_id2]
    security_groups = var.worker_sg
  }
}

