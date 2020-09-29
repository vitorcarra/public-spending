provider "aws" {
    region = var.aws_region
    profile = var.aws_profile
}

module "iam" {
    source = "./iam"
    
    project_name = var.project_name
}

module "network" {
    source = "./network"

    project_name = var.project_name
    postgres_port = var.postgres_port
    region = var.aws_region
}

module "route53" {
    source = "./route53"

    vpc_id = module.network.vpc_id
}

module "efs" {
    source = "./efs"
    project_name = var.project_name
    efs_subnet_id = module.network.private_subnet_group_id1
    efs_sg_id     = module.network.efs_sg_id
    role_ecs_name = module.iam.role_ecs_name
    region        = var.aws_region
}

module "ecs" {
    source = "./ecs"

    project_name = var.project_name
    region       = var.aws_region
    role_ecs_arn = module.iam.role_ecs_arn
    postgres_port          = var.postgres_port
    postgres_user          = var.postgres_user
    postgres_password      = var.postgres_password
    postgres_db            = var.postgres_db
    postgres_host          = module.rds.rds_host
    docker_image_airflow   = var.docker_image_airflow
    private_subnet_group_id1 = module.network.private_subnet_group_id1
    private_subnet_group_id2 = module.network.private_subnet_group_id2
    webserver_sg           =     module.network.webserver_sg
    redis_sg           =     module.network.redis_sg
    scheduler_sg           =     module.network.scheduler_sg
    flower_sg           =     module.network.flower_sg
    worker_sg           =     module.network.worker_sg
    alb_webserver_target_group = module.network.alb_webserver_target_group
    airflow_efs_id           = module.efs.airflow_efs_id
    airflow_efs_access_id    =  module.efs.airflow_efs_access_id
    rds_data_host            = module.rds.rds_host
    discovery_service_redis_arn = module.route53.discovery_service_redis_arn
}

module "rds" {
    source = "./rds"

    project_name = var.project_name
    postgres_port          = var.postgres_port
    postgres_user          = var.postgres_user
    postgres_password      = var.postgres_password
    postgres_db            = var.postgres_db
    vpc_security_group_ids = module.network.vpc_security_group_ids
    private_subnet_group_id1 = module.network.private_subnet_group_id1
    private_subnet_group_id2 = module.network.private_subnet_group_id2
}

module "ssm" {
    source = "./ssm"

    airflow_db_user = var.postgres_user
    airflow_db_password =  var.postgres_password
    airflow_db_name = var.postgres_db
    airflow_db_port = var.postgres_port
    airflow_fernet_key = var.fernet_key
}