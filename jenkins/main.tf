provider "aws" {
  profile = "karthik"
  region  = "us-east-1"
}

# VPC
resource "aws_vpc" "jenkins_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "jenkins-vpc"
  }
}

# Subnet
resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "jenkins-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name = "jenkins-igw"
  }
}

# Route Table
resource "aws_route_table" "jenkins_route_table" {
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }

  tags = {
    Name = "jenkins-route-table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "jenkins_route_table_association" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.jenkins_route_table.id
}

# Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.jenkins_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "jenkins-sg"
  }
}

# Jenkins IAM Role for Instance Profile
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy for Jenkins to Deploy Kubernetes or Other AWS Resources
resource "aws_iam_policy" "jenkins_policy" {
  name        = "jenkins-deployment-policy"
  description = "Policy to allow Jenkins to deploy resources on AWS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:*",
          "eks:*",
          "iam:PassRole",
          "s3:*",
          "autoscaling:*",
          "cloudformation:*",
          "elasticloadbalancing:*",
          "logs:*",
          "ssm:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach Jenkins Deployment Policy to Role
resource "aws_iam_role_policy_attachment" "jenkins_deployment_policy_attachment" {
  role       = aws_iam_role.jenkins_instance_role.name
  policy_arn = aws_iam_policy.jenkins_deployment_policy.arn
}

# Create Instance Profile for Jenkins EC2 Instance
resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_instance_role.name
}

# EC2 Instance for Jenkins
resource "aws_instance" "jenkins_instance" {
  ami                    = "ami-06b21ccaeff8cd686" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.jenkins_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = "jenkins-keypair"
  iam_instance_profile = aws_iam_instance_profile.jenkins_instance_profile.name

  user_data = file("jenkins-user-data.sh")

  tags = {
    Name = "Jenkins-Server"
  }
}
