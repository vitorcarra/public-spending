output "airflow_efs_id" {
    value = aws_efs_file_system.ps_efs.id
}

output "airflow_efs_access_id" {
    value = aws_efs_access_point.ps_efs_access.id
}