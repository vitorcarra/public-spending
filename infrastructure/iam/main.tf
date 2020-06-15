resource "aws_iam_role" "role_ecs" {
  name = "role-ecs-${var.project_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_policy" "policy_ecs" {
  name        = "ECSPolicy-${var.project_name}"
  description = "Policy to allow ecs communicate with required services"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "rds:StartDBCluster",
                "rds:DeleteGlobalCluster",
                "rds:RestoreDBInstanceFromS3",
                "rds:ResetDBParameterGroup",
                "s3:DeleteAccessPoint",
                "rds:PurchaseReservedDBInstancesOffering",
                "rds:ModifyDBParameterGroup",
                "rds:DownloadDBLogFilePortion",
                "s3:PutLifecycleConfiguration",
                "rds:AddRoleToDBCluster",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "rds:DeleteDBInstance",
                "s3:GetBucketWebsite",
                "s3:PutReplicationConfiguration",
                "rds:DeleteDBProxy",
                "s3:DeleteObjectVersionTagging",
                "rds:DeleteDBInstanceAutomatedBackup",
                "s3:GetObjectLegalHold",
                "s3:GetBucketNotification",
                "s3:GetReplicationConfiguration",
                "s3:PutObject",
                "s3:PutBucketNotification",
                "rds:DeleteDBSecurityGroup",
                "s3:PutBucketObjectLockConfiguration",
                "s3:CreateJob",
                "s3:GetLifecycleConfiguration",
                "s3:GetInventoryConfiguration",
                "s3:GetBucketTagging",
                "s3:ReplicateTags",
                "s3:ListBucket",
                "rds:DeleteOptionGroup",
                "rds:FailoverDBCluster",
                "rds:AddRoleToDBInstance",
                "s3:AbortMultipartUpload",
                "s3:PutBucketTagging",
                "rds:ModifyDBProxy",
                "s3:UpdateJobPriority",
                "rds:DeleteDBCluster",
                "s3:DeleteBucket",
                "s3:PutBucketVersioning",
                "s3:ListBucketMultipartUploads",
                "s3:PutMetricsConfiguration",
                "rds:ModifyEventSubscription",
                "s3:PutObjectVersionTagging",
                "s3:GetBucketVersioning",
                "s3:PutInventoryConfiguration",
                "rds:ModifyDBProxyTargetGroup",
                "rds:ModifyDBSnapshot",
                "rds:DeleteDBClusterSnapshot",
                "s3:GetAccountPublicAccessBlock",
                "rds:ListTagsForResource",
                "s3:PutBucketWebsite",
                "s3:ListAllMyBuckets",
                "s3:PutBucketRequestPayment",
                "s3:PutObjectRetention",
                "s3:GetBucketCORS",
                "rds:DeleteDBClusterParameterGroup",
                "rds:ApplyPendingMaintenanceAction",
                "rds:BacktrackDBCluster",
                "s3:GetObjectVersion",
                "rds:RemoveRoleFromDBInstance",
                "rds:ModifyDBSubnetGroup",
                "s3:PutAnalyticsConfiguration",
                "rds:RemoveRoleFromDBCluster",
                "s3:GetObjectVersionTagging",
                "s3:CreateBucket",
                "rds:CreateGlobalCluster",
                "rds:DeregisterDBProxyTargets",
                "s3:ReplicateObject",
                "s3:GetObjectAcl",
                "s3:GetBucketObjectLockConfiguration",
                "s3:DeleteBucketWebsite",
                "rds:AddSourceIdentifierToSubscription",
                "rds:CopyDBParameterGroup",
                "s3:GetObjectVersionAcl",
                "rds:CreateDBProxy",
                "rds:ModifyDBInstance",
                "rds:ModifyDBClusterParameterGroup",
                "rds:RegisterDBProxyTargets",
                "rds:ModifyDBClusterSnapshotAttribute",
                "s3:HeadBucket",
                "rds:CopyDBClusterParameterGroup",
                "s3:DeleteObjectTagging",
                "s3:GetBucketPolicyStatus",
                "rds:CreateDBClusterEndpoint",
                "rds:StopDBCluster",
                "s3:GetObjectRetention",
                "rds:CancelExportTask",
                "s3:ListJobs",
                "rds:DeleteDBSnapshot",
                "s3:PutObjectLegalHold",
                "s3:PutBucketCORS",
                "rds:RemoveFromGlobalCluster",
                "rds:PromoteReadReplica",
                "rds:StartDBInstance",
                "rds:StopActivityStream",
                "s3:ListMultipartUploadParts",
                "rds:RestoreDBClusterFromS3",
                "rds:DeleteDBSubnetGroup",
                "s3:GetObject",
                "rds:RestoreDBInstanceFromDBSnapshot",
                "s3:DescribeJob",
                "s3:PutBucketLogging",
                "rds:ModifyDBClusterEndpoint",
                "rds:ModifyDBCluster",
                "s3:GetAnalyticsConfiguration",
                "rds:DeleteDBParameterGroup",
                "s3:GetObjectVersionForReplication",
                "rds:ModifyDBSnapshotAttribute",
                "rds:PromoteReadReplicaDBCluster",
                "s3:CreateAccessPoint",
                "rds:ModifyOptionGroup",
                "s3:GetAccessPoint",
                "rds:RestoreDBClusterFromSnapshot",
                "s3:PutAccelerateConfiguration",
                "s3:DeleteObjectVersion",
                "rds:StartExportTask",
                "s3:GetBucketLogging",
                "s3:ListBucketVersions",
                "s3:RestoreObject",
                "rds:StartActivityStream",
                "s3:GetAccelerateConfiguration",
                "s3:GetBucketPolicy",
                "s3:PutEncryptionConfiguration",
                "s3:GetEncryptionConfiguration",
                "s3:GetObjectVersionTorrent",
                "rds:DeleteEventSubscription",
                "rds:RemoveSourceIdentifierFromSubscription",
                "s3:GetBucketRequestPayment",
                "rds:DeleteDBClusterEndpoint",
                "s3:GetAccessPointPolicyStatus",
                "rds:RevokeDBSecurityGroupIngress",
                "s3:GetObjectTagging",
                "s3:GetMetricsConfiguration",
                "rds:ModifyCurrentDBClusterCapacity",
                "rds:ResetDBClusterParameterGroup",
                "rds:RestoreDBClusterToPointInTime",
                "s3:GetBucketPublicAccessBlock",
                "s3:ListAccessPoints",
                "rds:CopyDBSnapshot",
                "rds:CopyDBClusterSnapshot",
                "s3:UpdateJobStatus",
                "rds:StopDBInstance",
                "s3:GetBucketAcl",
                "rds:CopyOptionGroup",
                "s3:GetObjectTorrent",
                "rds:RebootDBInstance",
                "rds:ModifyGlobalCluster",
                "rds:DescribeDBClusterSnapshots",
                "rds:DownloadCompleteDBLogFile",
                "s3:GetBucketLocation",
                "s3:GetAccessPointPolicy",
                "s3:ReplicateDelete",
                "rds:RestoreDBInstanceToPointInTime"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "role_ecs_attach" {
  role       = aws_iam_role.role_ecs.name
  policy_arn = aws_iam_policy.policy_ecs.arn
}