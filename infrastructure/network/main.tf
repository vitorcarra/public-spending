resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"

  tags = {
    Name = var.project_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "igw-" + var.project_name
  }
}

resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = var.project_name + "-private"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.2.0/24"

  tags = {
    Name = var.project_name + "-public"
  }
}

resource "aws_route_table" "rt_private" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "rt-private"
  }
}

resource "aws_route_table_association" "rt_assoc_private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.rt_private.id
}

resource "aws_route_table" "rt_public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "192.168.2.0/24"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name = "rt-public"
  }
}
