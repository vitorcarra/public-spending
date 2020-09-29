output "role_ecs_arn" {
    value = aws_iam_role.role_ecs.arn
}

output "role_ecs_name" {
    value = aws_iam_role.role_ecs.name
}