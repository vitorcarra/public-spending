data "aws_caller_identity" "current" {}

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
  security_groups = [var.efs_sg_id]
}

resource "aws_efs_access_point" "ps_efs_access" {
  file_system_id = aws_efs_file_system.ps_efs.id
  root_directory {
    path = "/dags"
  }
}

resource "aws_efs_file_system_policy" "policy" {
  file_system_id = aws_efs_file_system.ps_efs.id

  policy = <<POLICY
{
  "Version" : "2012-10-17",
  "Id" : "efs-policy-wizard-f9497a38-9197-41fe-b3f6-26fdde954024",
  "Statement" : [ 
  {
    "Sid" : "efs-statement-e9715be8-23bf-441b-a8ef-934a2d7a2af8",
    "Effect" : "Allow",
    "Principal" : {
      "AWS" : "*"
    },
    "Action" : [ "elasticfilesystem:ClientMount", "elasticfilesystem:ClientRootAccess", "elasticfilesystem:ClientWrite" ],
    "Resource" : "${aws_efs_file_system.ps_efs.arn}"
  }, 
  {
      "Sid": "EcsOnFargateCloudCmdTaskReadAccess",
      "Effect": "Allow",
      "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.role_ecs_name}"
      },
      "Action": ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientWrite", "elasticfilesystem:ClientRootAccess"],
      "Resource": "${aws_efs_file_system.ps_efs.arn}",
      "Condition": {
          "StringEquals": {
              "elasticfilesystem:AccessPointArn": "arn:aws:elasticfilesystem:${var.region}:${data.aws_caller_identity.current.account_id}:access-point/${aws_efs_access_point.ps_efs_access.id}"
          }
      }
  } 
  ]
}
POLICY

}