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
    allow_ip = var.allow_ip
    postgres_port = var.postgres_port
    region = var.aws_region
}

module "ecs" {
    source = "./ecs"

    project_name = var.project_name
    role_ecs_arn = module.iam.role_ecs_arn
    postgres_port          = var.postgres_port
    postgres_user          = var.postgres_user
    postgres_password      = var.postgres_password
    postgres_db            = var.postgres_db
    postgres_host          = module.rds.rds_host
    docker_image           = "teste"
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