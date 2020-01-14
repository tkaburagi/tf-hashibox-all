resource "aws_iam_user" "training" {
  count = var.workstations

  name = "${var.namespace}-${element(var.animals, count.index)}"
  path = "/${var.namespace}/"
}

resource "aws_iam_access_key" "training" {
  count = var.workstations
  user  = element(aws_iam_user.training.*.name, count.index)
}

data "template_file" "iam_policy" {
  count    = var.workstations
  template = file("${path.module}/templates/policies/iam_policy.json.tpl")

  vars = {
    identity          = element(aws_iam_user.training.*.name, count.index)
    region            = var.region
    owner_id          = aws_security_group.training.owner_id
    ami_id            = data.aws_ami.ubuntu.id
    subnet_id         = element(aws_subnet.training.*.id, count.index)
    security_group_id = aws_security_group.training.id
  }
}

# Create a limited policy for this user - this policy grants permission for the
# user to do incredibly limited things in the environment, such as launching a
# specific instance provided it has their authorization tag, deleting instances
# they have created, and describing instance data.
resource "aws_iam_user_policy" "training" {
  count  = var.workstations
  name   = "policy-${element(aws_iam_user.training.*.name, count.index)}"
  user   = element(aws_iam_user.training.*.name, count.index)
  policy = element(data.template_file.iam_policy.*.rendered, count.index)
}

resource "random_string" "wetty" {
  length  = 16
  special = true
}

data "template_file" "workstation" {
  count = var.workstations

  template = join(
    "\n",
    [
      file("${path.module}/templates/shared/base.sh"),
      file("${path.module}/templates/shared/docker.sh"),
      file("${path.module}/templates/workstation/user.sh"),
      file("${path.module}/templates/workstation/consul.sh"),
      file("${path.module}/templates/workstation/vault.sh"),
      file("${path.module}/templates/workstation/postgres.sh"),
      file("${path.module}/templates/workstation/terraform.sh"),
      file("${path.module}/templates/workstation/tools.sh"),
      file("${path.module}/templates/workstation/nomad.sh"),
      file("${path.module}/templates/workstation/webterminal.sh"),
      file("${path.module}/templates/shared/cleanup.sh"),
    ],
  )

  vars = {
    namespace = var.namespace
    node_name = element(aws_iam_user.training.*.name, count.index)
    me_ca     = tls_self_signed_cert.root.cert_pem
    me_cert   = element(tls_locally_signed_cert.workstation.*.cert_pem, count.index)
    me_key    = element(tls_private_key.workstation.*.private_key_pem, count.index)
    # User
    training_username = var.training_username
    training_password = var.training_password
    identity          = element(aws_iam_user.training.*.name, count.index)
    # Consul
    consul_url            = var.consul_url
    consul_gossip_key     = base64encode(random_id.consul_gossip_key.hex)
    consul_join_tag_key   = "ConsulJoin"
    consul_join_tag_value = local.consul_join_tag_value
    # Terraform
    terraform_url     = var.terraform_url
    region            = var.region
    ami_id            = data.aws_ami.ubuntu.id
    subnet_id         = element(aws_subnet.training.*.id, count.index)
    security_group_id = aws_security_group.training.id
    access_key        = element(aws_iam_access_key.training.*.id, count.index)
    secret_key        = element(aws_iam_access_key.training.*.secret, count.index)
    # Tools
    consul_template_url   = var.consul_template_url
    envconsul_url         = var.envconsul_url
    packer_url            = var.packer_url
    sentinel_url          = var.sentinel_url
    dashboard_service_url = var.dashboard_service_url
    counting_service_url  = var.counting_service_url
    # Nomad
    nomad_url = var.nomad_url
    # Vault
    vault_url = var.vault_url
    #Wetty
    wetty_pw = random_string.wetty.result
  }
}

# Gzip cloud-init config
data "template_cloudinit_config" "workstation" {
  count = var.workstations

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = element(data.template_file.workstation.*.rendered, count.index)
  }
}

# IAM
resource "aws_iam_role" "workstation" {
  count              = var.workstations
  name               = "${element(aws_iam_user.training.*.name, count.index)}-workstation"
  assume_role_policy = file("${path.module}/templates/policies/assume-role.json")
}

resource "aws_iam_policy" "workstation" {
  count       = var.workstations
  name        = "${element(aws_iam_user.training.*.name, count.index)}-workstation"
  description = "Allows student ${element(aws_iam_user.training.*.name, count.index)} to use their workstation."
  policy      = element(data.template_file.iam_policy.*.rendered, count.index)
}

resource "aws_iam_policy_attachment" "workstation" {
  count      = var.workstations
  name       = "${element(aws_iam_user.training.*.name, count.index)}-workstation"
  roles      = [element(aws_iam_role.workstation.*.name, count.index)]
  policy_arn = element(aws_iam_policy.workstation.*.arn, count.index)
}

resource "aws_iam_instance_profile" "workstation" {
  count = var.workstations
  name  = "${element(aws_iam_user.training.*.name, count.index)}-workstation"
  role  = element(aws_iam_role.workstation.*.name, count.index)
}

resource "aws_instance" "workstation" {
  count = var.workstations

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_type
  key_name      = aws_key_pair.training.id

  subnet_id              = element(aws_subnet.training.*.id, count.index)
  iam_instance_profile   = element(aws_iam_instance_profile.workstation.*.name, count.index)
  vpc_security_group_ids = [aws_security_group.training.id]

  tags = {
    Name       = element(aws_iam_user.training.*.name, count.index)
    owner      = var.owner
    created-by = var.created-by
  }

  user_data = element(
    data.template_cloudinit_config.workstation.*.rendered,
    count.index,
  )
}

output "workstations" {
  value = [aws_instance.workstation.*.public_ip]
}

output "workstation_webterminal_links" {
  value = formatlist(
    "https://%s:3000/wetty/ssh/%s",
    aws_instance.workstation.*.public_ip,
    var.training_username,
  )
}

