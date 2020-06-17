resource "aws_db_subnet_group" "default" {
  name       = "vpc-subnet-group-${var.project_name}"
  subnet_ids = [var.private_subnet_group_id1, var.private_subnet_group_id2]
}

resource "aws_db_instance" "default" {
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "9.6.17"
  instance_class          = "db.t2.micro"
  name                    = var.postgres_db
  username                = var.postgres_user
  password                = var.postgres_password
  parameter_group_name    = "default.postgres9.6"
  identifier              = "${var.project_name}-postgres"
  port                    = var.postgres_port
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.default.name
  skip_final_snapshot    = true
}