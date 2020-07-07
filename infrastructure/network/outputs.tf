output "vpc_security_group_ids" {
    value = [aws_security_group.rds_sg.id]
}

output "private_subnet_group_id1" {
    value = aws_subnet.private1.id
}

output "private_subnet_group_id2" {
    value = aws_subnet.private2.id
}

output "webserver_sg" {
    value = [aws_security_group.webserver_sg.id]
}

output "alb_webserver_target_group" {
    value = aws_lb_target_group.alb_tg_webserver.arn
}

output "redis_sg" {
    value = [aws_security_group.redis_sg.id]
}

output "scheduler_sg" {
    value = [aws_security_group.scheduler_sg.id]
}