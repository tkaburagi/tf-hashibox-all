resource "aws_alb" "hashistack" {
  name = "${var.namespace}-hashistack"

  security_groups = [aws_security_group.training.id]
  subnets         = aws_subnet.training.*.id

  tags = {
    Name           = "${var.namespace}-hashistack"
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }
}

