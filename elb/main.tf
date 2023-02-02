data "aws_acm_certificate" "elb-cert" {
    domain = "*.devopslearnershub.xyz"
    statuses = ["ISSUED"]
}
resource "aws_security_group" "ELBSG" {
  name        = "ELB-SG"
  description = "Allows Connections to ELB"
  ingress {
    description = "Allows ssh connection from myip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.external.myipVal.result["internet_ip"]]
  }
  ingress {
    description      = "Allows connections across http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    ddescription     = "Allows connections across https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    description      = "Allows all egress connections"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name    = "ELB-SG"
    Project = "Vprofile"
  }

}
resource "aws_lb_target_group" "AppTG" {
  name        = "vprofile-app-TG"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.defaultVPC
  target_type = "instance"

  health_check {
    enabled           = true
    path              = "/login"
    port              = 8080
    healthy_threshold = 3
  }
  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 3600
  }

}
resource "aws_lb_target_group_attachment" "AppTG-Attach" {
  target_group_arn = aws_lb_target_group.AppTG.arn
  target_id        = var.AppID
}

resource "aws_lb" "Vprofile-ELB" {
  name               = "vprofile-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ELBSG.id]
  subnets            = [var.def_us-east-1a, var.def_us-east-1b, var.def_us-east-1c, var.def_us-east-1d, var.def_us-east-1e, var.def_us-east-1f]
}
resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = aws_lb.Vprofile-ELB.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.AppTG.arn
  }
  stickiness {
    enabled  = true
    duration = 3600
  }
}
resource "aws_lb_listener" "https-listener" {
  load_balancer_arn = aws_lb.Vprofile-ELB.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.elb-cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.AppTG.arn
  }
  stickiness {
    enabled  = true
    duration = 3600
  }
}
