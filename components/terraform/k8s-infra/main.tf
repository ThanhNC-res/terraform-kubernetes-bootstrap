locals {
  creator = can(split(":", data.aws_caller_identity.sts_current.user_id)[1]) ? (split(":", data.aws_caller_identity.sts_current.user_id)[1]) : split("/", data.aws_caller_identity.sts_current.arn)[1]

  modified_name = can(split(":", data.aws_caller_identity.sts_current.user_id)[1]) ? (split(":", data.aws_caller_identity.sts_current.user_id)[1]) : split("/", data.aws_caller_identity.sts_current.arn)[1]


  tags = merge(
    { "Creator" = local.creator },
    { "CreatedDate" = timestamp() },
    var.general_tags
  )
}

resource "aws_iam_role" "ssm_ec2_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ssm_ec2_role.name
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "private_sg" {
  name   = "private-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "public_ec2" {
  count                  = var.public_instance_params.instance_count
  ami                    = var.public_instance_params.ami_id
  instance_type          = var.public_instance_params.instance_type
  subnet_id              = aws_subnet.public.id
  key_name               = var.public_instance_params.key_name
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [aws_security_group.public_sg.id]

  tags = merge({
    Name = "Public-EC2-${count.index + 1}" },
    local.tags
  )
}

resource "aws_instance" "private_ec2" {
  count                  = var.private_instance_params.instance_count
  ami                    = var.private_instance_params.ami_id
  instance_type          = var.private_instance_params.instance_type
  subnet_id              = aws_subnet.private.id
  key_name               = var.private_instance_params.key_name
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [aws_security_group.public_sg.id]

  user_data = <<-EOF
            #!/bin/bash
            sudo yum update -y
            sudo yum install -y amazon-ssm-agent
            sudo systemctl enable amazon-ssm-agent
            sudo systemctl start amazon-ssm-agent
            EOF

  tags = merge({
    Name = "Private-EC2-${count.index + 1}" },
    local.tags
  )
}


