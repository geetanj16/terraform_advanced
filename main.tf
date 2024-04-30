# # Creating VPC
resource "aws_vpc" "My_VPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "My_VPC"
  }
}


# resource "aws_subnet" "public_subnets" {
#  #count      = length(var.public_subnet_cidrs)
#  vpc_id     = aws_vpc.main.id
#  cidr_block = ["10.0.0.0/18","10.0.64.0/18"]

#  tags = {
#    Name = "Public Subnet ${count.index + 1}"
#  }
# }

resource "aws_subnet" "public_subnets" {
  count      = length(["10.0.0.0/18", "10.0.64.0/18"])
  vpc_id     = aws_vpc.My_VPC.id
  cidr_block = element(["10.0.0.0/18", "10.0.64.0/18"], count.index)

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count      = length(["10.0.128.0/18", "10.0.192.0/18"])
  vpc_id     = aws_vpc.My_VPC.id
  cidr_block = element(["10.0.128.0/18", "10.0.192.0/18"], count.index)

  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.My_VPC.id

  tags = {
    Name = "internet-gateway"
  }
}


# resource "aws_internet_gateway_attachment" "vpc_igw" {
#   vpc_id         = aws_vpc.My_VPC.id
#   internet_gateway_id = aws_internet_gateway.igw.id
# }

resource "aws_eip" "nat_ip" {
  domain = "vpc"

  tags = {
    Name = "Nat-elastic"
  }
}

resource "aws_nat_gateway" "NAT-gateway" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.public_subnets[1].id
  tags = {
    Name = "Nat-gateway"
  }
}



resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.My_VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "publicRouteTable"
  }
}


resource "aws_route_table_association" "PUB_subnet_associations" {
  count          = length(aws_subnet.public_subnets[*].id)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}


# resource "aws_route_table" "private-rt" {
#   vpc_id = aws_vpc.vpc_test.id

#   tags = {
#     Name = "privateRouteTable"
#   }
# }

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.My_VPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT-gateway.id
  }

  tags = {
    Name = "privateRouteTable"
  }
}
resource "aws_route_table_association" "PRI_subnet_associations" {
  count          = length(aws_subnet.private_subnets[*].id)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# resource "aws_route_table_association" "rt-association-private" {
#   for_each       = aws_subnet.private-subnets
#   subnet_id      = each.value.id
#   route_table_id = aws_route_table.private-rt.id
# }

resource "aws_key_pair" "chat-key" {
  key_name   = "chat-key"
  public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "chat-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "chat-key"
}

resource "aws_security_group" "Security_front" {
  name   = "Security_front"
  description = "Security Group for frontend-instance"
  vpc_id = aws_vpc.My_VPC.id
  tags = {
    Name = "Security_front"
  }
  ingress{
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Security_backend" {
  name   = "Security_backend"
  description = "Security Group for backend-instance"
  vpc_id = aws_vpc.My_VPC.id
  tags = {
    Name = "Security_backend"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#creating security groups for database
resource "aws_security_group" "Security_data" {
  name        = "daSecurity_data"
  description = "Security Group for database-instance"
  vpc_id      = aws_vpc.My_VPC.id
  tags = {
    Name = "daSecurity_data"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "Frontend-instance" {
    ami                         = "ami-0b8b44ec9a8f90422"
    instance_type               = "t2.micro"
    vpc_security_group_ids      = [aws_security_group.Security_front.id]
    associate_public_ip_address = true
    key_name                    = aws_key_pair.chat-key.key_name
    subnet_id                   = aws_subnet.public_subnets[0].id
    tags = {
        Name = "Frontend-instance"
    }
}
resource "aws_instance" "Backend-instance" {
    ami                         = "ami-0b8b44ec9a8f90422"
    instance_type               = "t2.micro"
    vpc_security_group_ids      = [aws_security_group.Security_backend.id]
    associate_public_ip_address = false
    key_name                    = aws_key_pair.chat-key.key_name
    subnet_id                   = aws_subnet.public_subnets[0].id
    tags = {
        Name = "Backend-instance"
    }
}
resource "aws_instance" "Database-instance" {
    ami                         = "ami-0b8b44ec9a8f90422"
    instance_type               = "t2.micro"
    vpc_security_group_ids      = [aws_security_group.Security_data.id]
    associate_public_ip_address = false
    key_name                    = aws_key_pair.chat-key.key_name
    subnet_id                   = aws_subnet.public_subnets[0].id
    tags = {
        Name = "Database-instance"
    }
}
