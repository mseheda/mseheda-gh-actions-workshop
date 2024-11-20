provider aws {
  region = "us-east-1"
}

resource aws_vpc silly_vpc {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true  
}

# Internet Gateway
resource aws_internet_gateway igw {
  vpc_id = aws_vpc.silly_vpc.id
}

# Public Subnets in each Availability Zone
resource aws_subnet public_subnet_a {
  vpc_id            = aws_vpc.silly_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource aws_subnet public_subnet_b {
  vpc_id            = aws_vpc.silly_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource aws_subnet public_subnet_c {
  vpc_id            = aws_vpc.silly_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true
}

# Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.silly_vpc.id

  route {
    cidr_block = "0.0.0.0/0"  # All internet traffic
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_subnet_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_c" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.public_route_table.id
}

resource aws_security_group minikubeEC2_sg {
  name        = "minikube-sg"
  description = "Allow SSH and NodePort traffic for Minikube"
  vpc_id = aws_vpc.silly_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource aws_instance minikubeEC2 {
  ami                         = "ami-0bcf98c2c6db6c5f4" 
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.public_subnet_a.id
  key_name                    = var.key_pair_name
  security_groups             = [aws_security_group.minikubeEC2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "minikubeEC2"
  }

  root_block_device {
    volume_size = 20
  }

  user_data = templatefile("${path.module}/script.sh", {})
}

output "ec2_public_ip" {
  value = aws_instance.minikubeEC2.public_ip
}
