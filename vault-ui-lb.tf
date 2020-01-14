resource "aws_alb_target_group" "vault" {
  name_prefix = "vault"

  port     = "8200"
  vpc_id   = aws_vpc.training.id
  protocol = "HTTPS"

  health_check {
    interval          = "5"
    timeout           = "2"
    path              = "/v1/sys/health"
    port              = "8200"
    protocol          = "HTTPS"
    matcher           = "200,429"
    healthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "vault" {
  load_balancer_arn = aws_alb.hashistack.arn

  port     = "8200"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.vault.arn
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "vault" {
  count            = var.servers
  target_group_arn = aws_alb_target_group.vault.arn
  target_id        = element(aws_instance.server.*.id, count.index)
  port             = "8200"
}

output "vault-ui" {
  value = "${aws_alb.hashistack.dns_name}:8200"
}

