resource "aws_alb_target_group" "consul-ui" {
  name_prefix = "consul"
  port        = "8500"
  vpc_id      = aws_vpc.training.id
  protocol    = "HTTP"

  health_check {
    interval          = "5"
    timeout           = "2"
    path              = "/v1/health/node/my-node"
    port              = "8500"
    protocol          = "HTTP"
    healthy_threshold = 2
    matcher           = 200
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "consul-ui" {
  load_balancer_arn = aws_alb.hashistack.arn

  port     = "8500"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.consul-ui.arn
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "consul-ui" {
  count            = var.servers
  target_group_arn = aws_alb_target_group.consul-ui.arn
  target_id        = element(aws_instance.server.*.id, count.index)
  port             = "8500"
}

output "consul-ui" {
  value = "${aws_alb.hashistack.dns_name}:8500"
}

