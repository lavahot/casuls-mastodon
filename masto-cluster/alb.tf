resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow inbound traffic from the internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
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

resource "aws_lb" "masto_lb" {
  name               = "masto-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "masto_tg_https" {
  name        = "masto-tg-https"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 10
    unhealthy_threshold = 10
    protocol            = "HTTPS"
  }
}

# http target group

resource "aws_lb_target_group" "masto_tg_http" {
  name        = "masto-tg-http"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 5
    unhealthy_threshold = 10
    protocol            = "HTTP"
  }
}

resource "aws_lb_listener" "masto_http_listener" {
  load_balancer_arn = aws_lb.masto_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Create HTTPS listener for the load balancer

resource "aws_lb_listener" "masto_https_listener" {
  load_balancer_arn = aws_lb.masto_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.masto_tg_http.arn
  }
}
