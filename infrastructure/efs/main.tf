resource "aws_efs_file_system" "ps_efs" {
  performance_mode = "generalPurpose"
  encrypted = true

  tags = {
    Name = "${var.project_name}-efs-airflow"
    Project = var.project_name
  }
}

resource "aws_efs_mount_target" "ps_efs_mount" {
  file_system_id = aws_efs_file_system.ps_efs.id
  subnet_id      = var.efs_subnet_id
}