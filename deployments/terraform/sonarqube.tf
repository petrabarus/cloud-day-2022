/**
 * Install sonarqube.
 */


data "aws_ami" "bitnami_sonarqube" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-sonarqube-9.5.0-5-r03-linux-debian-11-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [
    "979382823631" // Bitnami
  ]
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "${local.name}-sonarqube-key"
  create_private_key = true
}

resource "aws_security_group" "sonarqube_sg" {
  name   = "${local.name}-sonarqube-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow SSH"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_network_interface" "sonarqube_iface" {
  subnet_id = aws_subnet.public[0].id
  security_groups = [
    aws_security_group.sonarqube_sg.id
  ]

  tags = {
    Name = "${local.name}-sonarqube-iface"
  }
}


resource "aws_iam_role" "sonarqube_role" {
  name = "${local.name}-sonarqube-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "sonarqube_instance_profile" {
  name = "${local.name}-sonarqube-instance-profile"
  role = aws_iam_role.sonarqube_role.name
}

resource "aws_instance" "sonarqube" {
  depends_on = [
  ]

  ami = data.aws_ami.bitnami_sonarqube.id

  // Just use nano instance type for now to keep the cost low.
  instance_type        = "t3a.medium"
  key_name             = module.key_pair.key_pair_name
  iam_instance_profile = aws_iam_instance_profile.sonarqube_instance_profile.name

  network_interface {
    network_interface_id = aws_network_interface.sonarqube_iface.id
    device_index         = 0
  }

  tags = {
    Name = "${local.name}-sonarqube"
  }
}

resource "aws_eip" "sonarqube_eip" {
  instance = aws_instance.sonarqube.id
  vpc      = true
  tags = {
    Name = "${local.name}-sonarqube-eip"
  }
}
