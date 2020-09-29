resource "aws_ssm_parameter" "airflow_db_user" {
  name  = "/prd/data/rds/postgres/airflow/user"
  type  = "String"
  value = var.airflow_db_user
  description = "airflow db user"
}

resource "aws_ssm_parameter" "airflow_db_password" {
  name  = "/prd/data/rds/postgres/airflow/password"
  type  = "String"
  value = var.airflow_db_password
  description = "airflow db pass"
}

resource "aws_ssm_parameter" "airflow_db_name" {
  name  = "/prd/data/rds/postgres/airflow/db-name"
  type  = "String"
  value = var.airflow_db_name
  description = "airflow user"
}

resource "aws_ssm_parameter" "airflow_db_port" {
  name  = "/prd/data/rds/postgres/airflow/port"
  type  = "String"
  value = var.airflow_db_port
  description = "airflow db port"
}

resource "aws_ssm_parameter" "airflow_fernet_key" {
  name  = "/prd/data/rds/postgres/airflow/fernet_key"
  type  = "String"
  value = var.airflow_fernet_key
  description = "airflow fernet key"
}