
data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_security_group" "loadbalancer_security_group" {
  name   = "${var.name}-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Allow HTTP from Outside"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.name}-alb-sg"
  }
}

resource "aws_lb" "main_load_balancer" {
  name    = "${var.name}-lb"
  subnets = var.public_subnets.*.id
  security_groups = [
    aws_security_group.loadbalancer_security_group.id
  ]
}

resource "aws_lb_target_group" "main_load_balancer_target_group" {
  name     = "${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    matcher             = "200,302"
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 2
  }

  tags = {
    Name = "${var.name}-tg"
  }
}

resource "aws_lb_listener" "load_balancer_listener" {
  load_balancer_arn = aws_lb.main_load_balancer.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.main_load_balancer_target_group.id
    type             = "forward"
  }
}


resource "aws_security_group" "task_security_group" {
  name   = "${var.name}-task-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow HTTP from load balancer"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    security_groups = [
      aws_security_group.loadbalancer_security_group.id
    ]
  }


  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-task-sg"
  }
}
