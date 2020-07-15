resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = var.project_name
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-${var.project_name}"
    Project = var.project_name
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true
  depends_on = [aws_internet_gateway.igw]
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.1.0/24"
  availability_zone_id = data.aws_availability_zones.available.zone_ids[0]

  tags = {
    Name = "${var.project_name}-private"
    Project = var.project_name
  }
}

resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.2.0/24"
  availability_zone_id = data.aws_availability_zones.available.zone_ids[1]

  tags = {
    Name = "${var.project_name}-private2"
    Project = var.project_name
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.3.0/24"

  availability_zone_id = data.aws_availability_zones.available.zone_ids[0]

  tags = {
    Name = "${var.project_name}-public"
    Project = var.project_name
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.4.0/24"
  availability_zone_id = data.aws_availability_zones.available.zone_ids[1]

  tags = {
    Name = "${var.project_name}-public2"
    Project = var.project_name
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-${var.project_name}"
    Project = var.project_name
  }
}


resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.project_name}-rt-private"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "rt_assoc_private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.rt_private.id
}

resource "aws_route_table_association" "rt_assoc_private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.rt_private.id
}

resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "rt_assoc_public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "rt_assoc_public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.rt_public.id
}



resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [aws_subnet.private1.id,aws_subnet.private2.id]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "192.168.1.0/24"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 110
    action     = "allow"
    cidr_block = "192.168.2.0/24"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8080
    to_port    = 8080
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-nacl-private"
    Project = var.project_name
  }
}

resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [aws_subnet.public.id, aws_subnet.public2.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8080
    to_port    = 8080
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 150
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  

  tags = {
    Name = "${var.project_name}-nacl-public"
    Project = var.project_name
  }
}


# Security Groups
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-postgres-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Enable postgres access"
    from_port   = var.postgres_port
    to_port     = var.postgres_port
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private1.cidr_block, aws_subnet.private2.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Name = "${var.project_name}-postgres-sg"
  }
}

resource "aws_security_group" "vpc_allow_sg" {
  name        = "${var.project_name}-vpc_allow_sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Enable VPC connection"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Enable S3 endpoint"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Name = "${var.project_name}-vpc_allow_sg"
  }
}

resource "aws_security_group" "webserver_sg" {
  name        = "${var.project_name}-webserver_sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Enable VPC connection"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Enable HTTP to S3 Endpoint"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  ingress {
    description = "Enable HTTP 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Name = "${var.project_name}-webserver_sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb_sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Enable HTTP 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Enable HTTP 8080"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Enable SG Webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.webserver_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Name = "${var.project_name}-alb_sg"
  }
}

resource "aws_security_group_rule" "sgr_webserver" {
  type              = "ingress"
  description = "Enable all traffic alb"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id = aws_security_group.webserver_sg.id
}

resource "aws_security_group_rule" "sgr_webserver1" {
  type              = "ingress"
  description = "Enable workers"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.worker_sg.id
  security_group_id = aws_security_group.webserver_sg.id
}

resource "aws_security_group" "redis_sg" {
  name        = "${var.project_name}-redis-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Enable airflow webserver access"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [aws_security_group.webserver_sg.id]
  }

  ingress {
    description = "Enable VPC connection"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Enable HTTP to S3 Endpoint"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Name = "${var.project_name}-redis-sg"
  }
}

resource "aws_security_group_rule" "sgr_redis" {
  type              = "ingress"
  description = "Enable scheduler"
  from_port   = 6379
  to_port     = 6379
  protocol    = "tcp"
  source_security_group_id = aws_security_group.scheduler_sg.id
  security_group_id = aws_security_group.redis_sg.id
}

resource "aws_security_group_rule" "sgr_redis1" {
  type              = "ingress"
  description = "Enable worker"
  from_port   = 6379
  to_port     = 6379
  protocol    = "tcp"
  source_security_group_id = aws_security_group.worker_sg.id
  security_group_id = aws_security_group.redis_sg.id
}

resource "aws_security_group_rule" "sgr_redis2" {
  type              = "ingress"
  description = "Enable flower"
  from_port   = 6379
  to_port     = 6379
  protocol    = "tcp"
  source_security_group_id = aws_security_group.flower_sg.id
  security_group_id = aws_security_group.redis_sg.id
}

resource "aws_security_group" "worker_sg" {
  name        = "${var.project_name}-worker-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Enable airflow webserver access"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    security_groups = [aws_security_group.webserver_sg.id]
  }

  ingress {
    description = "Enable redis access"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    security_groups = [aws_security_group.redis_sg.id]
  }

  ingress {
    description = "Enable VPC connection"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Enable HTTP to S3 Endpoint"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Name = "${var.project_name}-worker-sg"
  }
}

resource "aws_security_group" "scheduler_sg" {
  name        = "${var.project_name}-scheduler-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Enable airflow webserver access"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    security_groups = [aws_security_group.webserver_sg.id]
  }

  ingress {
    description = "Enable redis access"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    security_groups = [aws_security_group.redis_sg.id]
  }

  ingress {
    description = "Enable VPC connection"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Enable HTTP to S3 Endpoint"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Name = "${var.project_name}-scheduler-sg"
  }
}

resource "aws_security_group" "flower_sg" {
  name        = "${var.project_name}-flower-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Enable airflow webserver access"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    security_groups = [aws_security_group.webserver_sg.id]
  }

  ingress {
    description = "Enable redis access"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    security_groups = [aws_security_group.redis_sg.id]
  }

  ingress {
    description = "Enable VPC connection"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Enable HTTP to S3 Endpoint"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Name = "${var.project_name}-flower-sg"
  }
}

# VPC Endpoints
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.rt_private.id]

  tags = {
    Name = "${var.project_name}-s3-vpce"
    Project = var.project_name
  }
}

resource "aws_vpc_endpoint" "ecr" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private1.id, aws_subnet.private2.id]

  security_group_ids = [
    "${aws_security_group.vpc_allow_sg.id}",
  ]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ecr-dkr-vpce"
    Project = var.project_name
  }
}

resource "aws_vpc_endpoint" "ecr-api" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private1.id, aws_subnet.private2.id]

  security_group_ids = [
    "${aws_security_group.vpc_allow_sg.id}",
  ]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ecr-api-vpce"
    Project = var.project_name
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private1.id, aws_subnet.private2.id]

  security_group_ids = [
    "${aws_security_group.vpc_allow_sg.id}",
  ]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-logs-vpce"
    Project = var.project_name
  }
}


# ALB
resource "aws_lb" "alb_airflow" {
  name               = "${var.project_name}-alb-airflow"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "alb_tg_webserver" {
  name        = "albwebserver"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    protocol = "HTTP"
    path = "/"
    port = 8080
    matcher = 302
    interval = 60
    timeout = 30
  }

  depends_on = [aws_lb.alb_airflow]
}

resource "aws_lb_listener" "alb_webserver_listener" {
  load_balancer_arn = aws_lb.alb_airflow.arn
  port              = "8080"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_webserver.arn
  }
}


resource "aws_lb" "alb_redis" {
  name               = "${var.project_name}-alb-redis"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.private1.id, aws_subnet.private2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "alb_tg_redis" {
  name        = "albwredis"
  port        = 6379
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  stickiness {
    enabled = false
    type = "lb_cookie"
  }

  depends_on = [aws_lb.alb_redis]
}

resource "aws_lb_listener" "alb_redis_listener" {
  load_balancer_arn = aws_lb.alb_redis.arn
  port              = "6379"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_redis.arn
  }
}

