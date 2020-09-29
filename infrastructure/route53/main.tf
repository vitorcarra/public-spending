resource "aws_service_discovery_private_dns_namespace" "public_spending" {
  name        = "data.local"
  description = "Data namespace for public spending"
  vpc         = var.vpc_id
}



resource "aws_service_discovery_service" "discovery_service_redis_data" {
  name = "redis"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.public_spending.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}