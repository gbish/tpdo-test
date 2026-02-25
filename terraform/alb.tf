# Create an Application Load Balancer so the ECS app can be accessed
resource "aws_lb" "tpdo" {
  name               = "tpdo"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  # Use the public subnets to place ALB so it's publically available
  subnets = module.vpc.public_subnets

  tags = {
    Service = var.project_name
  }
}

resource "aws_lb_target_group" "hello_world" {
  name                 = "${var.project_name}-hello-world-tg"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 60
  vpc_id               = module.vpc.vpc_id

  # Ensure the container is healthy, if not the load balancer won't route traffic to it
  health_check {
    interval            = 15
    path                = "/"
    port                = 8080
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-204"
  }
}

# Forward our HTTP traffic to the target group so our app can be exposed
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.tpdo.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hello_world.arn
  }
}
