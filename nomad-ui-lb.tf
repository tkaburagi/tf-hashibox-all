resource "aws_alb_target_group" "nomad-ui" {
  name_prefix = "nomad"
  port        = "4646"
  vpc_id      = aws_vpc.training.id
  protocol    = "HTTPS"

  health_check {
    interval          = "5"
    timeout           = "2"
    path              = "/v1/agent/health"
    port              = "4646"
    protocol          = "HTTPS"
    healthy_threshold = 2
    matcher           = 200
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "nomad-ui" {
  load_balancer_arn = aws_alb.hashistack.arn

  port     = "4646"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.nomad-ui.arn
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "nomad-ui" {
  count            = var.servers
  target_group_arn = aws_alb_target_group.nomad-ui.arn
  target_id        = element(aws_instance.server.*.id, count.index)
  port             = "4646"
}

output "nomad-ui" {
  value = "${aws_alb.hashistack.dns_name}:4646"
}

