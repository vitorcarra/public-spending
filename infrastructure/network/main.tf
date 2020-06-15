resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"

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

  tags = {
    Name = "${var.project_name}-public"
    Project = var.project_name
  }
}

resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-private"
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
    Name = "rt-public"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "rt_assoc_public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt_public.id
}


resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [aws_subnet.private1.id,aws_subnet.private2.id]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.allow_ip
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "nacl-private"
    Project = var.project_name
  }
}

resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [aws_subnet.public.id]

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

  tags = {
    Name = "nacl-public"
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
  }
}