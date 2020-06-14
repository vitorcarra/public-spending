provider "aws" {
    region = var.aws_region
    profile = var.aws_profile
}

module "iam" {
    source = "./iam"
}

module "network" {
    source = "./network"

    project_name = var.project_name
}

module "ecs" {
    source = "./ecs"
}