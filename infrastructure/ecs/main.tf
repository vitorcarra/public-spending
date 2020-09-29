resource "aws_ecs_cluster" "airflow_celery1" {
  name = "airflow-celery1"
  capacity_providers = ["FARGATE"]

  tags = {
    Project = var.project_name
  }
}

data "aws_caller_identity" "current" {}

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
              "containerPath": "/usr/local/airflow/dags",
              "sourceVolume": "airflow-dags-efs"
          }
        ],
        "secrets": [
            { "name": "POSTGRES_USER", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/user"},
            { "name": "POSTGRES_PORT", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/port"},
            { "name": "POSTGRES_DB", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/db-name"},
            { "name": "POSTGRES_PASSWORD", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/password"},
            { "name": "AIRFLOW__CORE__FERNET_KEY", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/fernet_key"}
        ],
        "environment": [
          { "name": "POSTGRES_HOST", "value": "${var.rds_data_host}"}
        ]
    }
  ]
  TASK_DEFINITION

  volume {
    name = "airflow-dags-efs"

    efs_volume_configuration {
      file_system_id          = var.airflow_efs_id
      transit_encryption      = "ENABLED"
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
        "image": "redis:5",
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
        "secrets": [
            { "name": "POSTGRES_USER", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/user"},
            { "name": "POSTGRES_PORT", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/port"},
            { "name": "POSTGRES_DB", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/db-name"},
            { "name": "POSTGRES_PASSWORD", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/password"},
            { "name": "AIRFLOW__CORE__FERNET_KEY", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/fernet_key"}
        ],
        "environment": [
            { "name": "POSTGRES_HOST", "value": "${var.rds_data_host}"}
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
  platform_version = "1.4.0"
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

  service_registries {
    registry_arn = var.discovery_service_redis_arn
    container_name = "airflow-redis"
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
        "mountPoints": [
          {
              "containerPath": "/usr/local/airflow/dags",
              "sourceVolume": "airflow-dags-efs"
          }
        ],
        "secrets": [
            { "name": "POSTGRES_USER", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/user"},
            { "name": "POSTGRES_PORT", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/port"},
            { "name": "POSTGRES_DB", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/db-name"},
            { "name": "POSTGRES_PASSWORD", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/password"},
            { "name": "AIRFLOW__CORE__FERNET_KEY", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/fernet_key"}
        ],
        "environment": [
            { "name": "POSTGRES_HOST", "value": "${var.rds_data_host}"},
            { "name": "EXECUTOR", "value": "Celery"},
            { "name": "LOAD_EX", "value": "n"},
            { "name": "REDIS_HOST", "value": "redis.data.local"}
        ]
    }
  ]
  TASK_DEFINITION

  volume {
    name = "airflow-dags-efs"

    efs_volume_configuration {
      file_system_id          = var.airflow_efs_id
      transit_encryption      = "ENABLED"
    } 
  }

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
  platform_version = "1.4.0"

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
            { "name": "REDIS_HOST", "value": "redis.data.local"}
        ],
        "mountPoints": [
          {
              "containerPath": "/usr/local/airflow/dags",
              "sourceVolume": "airflow-dags-efs"
          }
        ]
    }
  ]
  TASK_DEFINITION

  volume {
    name = "airflow-dags-efs"

    efs_volume_configuration {
      file_system_id          = var.airflow_efs_id
      transit_encryption      = "ENABLED"
    } 
  }

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
  platform_version = "1.4.0"

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
        "secrets": [
            { "name": "POSTGRES_USER", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/user"},
            { "name": "POSTGRES_PORT", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/port"},
            { "name": "POSTGRES_DB", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/db-name"},
            { "name": "POSTGRES_PASSWORD", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/password"},
            { "name": "AIRFLOW__CORE__FERNET_KEY", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/prd/data/rds/postgres/airflow/fernet_key"}
        ],
        "mountPoints": [
          {
              "containerPath": "/usr/local/airflow/dags",
              "sourceVolume": "airflow-dags-efs"
          }
        ],
        "environment": [
            { "name": "POSTGRES_HOST", "value": "${var.rds_data_host}"},
            { "name": "REDIS_HOST", "value": "redis.data.local"}
        ]
    }
  ]
  TASK_DEFINITION

  volume {
    name = "airflow-dags-efs"

    efs_volume_configuration {
      file_system_id          = var.airflow_efs_id
      transit_encryption      = "ENABLED"
    } 
  }

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
  platform_version = "1.4.0"

  #depends_on      = ["aws_iam_role_policy.foo"]

  network_configuration {
    assign_public_ip = false
    subnets = [var.private_subnet_group_id1, var.private_subnet_group_id2]
    security_groups = var.worker_sg
  }
}

