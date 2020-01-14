variable "region" {
  description = "The region to create resources."
  default     = "us-east-1"
}

variable "servers" {
  description = "The number of data servers (consul, nomad, etc)."
  default     = "1"
}

variable "workstations" {
  description = "The number of workstations to create."
}

variable "ec2_type" {
  description = "EC2 instance type for the student workstation"
  default     = "t2.medium"
}

variable "consul_url" {
  description = "The url to download Consul."
  default     = "https://releases.hashicorp.com/consul/1.2.2/consul_1.2.2_linux_amd64.zip"
}

variable "packer_url" {
  description = "The url to download Packer."
  default     = "https://releases.hashicorp.com/packer/1.2.5/packer_1.2.5_linux_amd64.zip"
}

variable "sentinel_url" {
  description = "The url to download Sentinel simulator."
  default     = "https://releases.hashicorp.com/sentinel/0.10.4/sentinel_0.10.4_linux_amd64.zip"
}

variable "consul_template_url" {
  description = "The url to download Consul Template."
  default     = "https://releases.hashicorp.com/consul-template/0.21.0/consul-template_0.21.0_linux_amd64.zip"
}

variable "envconsul_url" {
  description = "The url to download Envconsul."
  default     = "https://releases.hashicorp.com/envconsul/0.9.0/envconsul_0.9.0_linux_amd64.zip"
}

variable "fabio_dockerhub_image" {
  description = "The dockerhub image for fabio."
  default     = "fabiolb/fabio:1.5.11-go1.11.5"
}

variable "nomad_url" {
  description = "The url to download nomad."
  default     = "https://releases.hashicorp.com/nomad/0.8.5/nomad_0.8.5_linux_amd64.zip"
}

variable "terraform_url" {
  description = "The url to download terraform."
  default     = "https://releases.hashicorp.com/terraform/0.12.6/terraform_0.12.6_linux_amd64.zip"
}

variable "vault_url" {
  description = "The url to download vault."
  default     = "https://releases.hashicorp.com/vault/1.2.2/vault_1.2.2_linux_amd64.zip"
}

variable "namespace" {
  description = <<EOH
The namespace to create the virtual training lab. This should describe the
training and must be unique to all current trainings. IAM users, workstations,
and resources will be scoped under this namespace.

It is best if you add this to your .tfvars file so you do not need to type
it manually with each run
EOH

}

variable "owner" {
  description = "IAM user responsible for lifecycle of cloud resources used for training"
}

variable "created-by" {
  description = "Tag used to identify resources created programmatically by Terraform"
  default     = "Terraform"
}

variable "sleep-at-night" {
  description = "Tag used by reaper to identify resources that can be shutdown at night"
  default     = false
}

variable "TTL" {
  description = "Hours after which resource expires, used by reaper. Do not use any unit. -1 is infinite."
  default     = "240"
}

locals {
  consul_join_tag_value = "${var.namespace}-${random_id.consul_join_tag_value.hex}"
}

variable "vpc_cidr_block" {
  description = "The top-level CIDR block for the VPC."
  default     = "10.1.0.0/16"
}

variable "cidr_blocks" {
  description = "The CIDR blocks to create the workstations in."
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "training_username" {
  description = "The username to attach to the user student's login as."
}

variable "training_password" {
  description = "The password to attach to the user student's login as."
}

variable "public_key" {
  description = "The contents of the SSH public key to use for connecting to the cluster."
}

variable "animals" {
  default = [
    "ant",
    "badger",
    "bat",
    "bear",
    "bee",
    "beetle",
    "bird",
    "bison",
    "buffalo",
    "bulldog",
    "butterfly",
    "camel",
    "cat",
    "catfish",
    "cheetah",
    "chicken",
    "chipmunk",
    "cobra",
    "coyote",
    "cricket",
    "crow",
    "deer",
    "dinosaur",
    "dolphin",
    "dove",
    "dragonfly",
    "duck",
    "eagle",
    "elephant",
    "elk",
    "falcon",
    "flamingo",
    "fox",
    "frog",
    "goldfish",
    "gopher",
    "gorilla",
    "grasshopper",
    "greyhound",
    "halibut",
    "hamster",
    "hawk",
    "hedgehog",
    "heron",
    "herring",
    "hornet",
    "horse",
    "hummingbird",
    "jaguar",
    "jellyfish",
    "kangaroo",
    "koala",
    "ladybug",
    "leopard",
    "lion",
    "lizard",
    "llama",
    "lobster",
    "lynx",
    "mackerel",
    "marlin",
    "mockingbird",
    "moose",
    "mosquito",
    "mussel",
    "octopus",
    "orca",
    "ostrich",
    "otter",
    "owl",
    "ox",
    "oyster",
    "panda",
    "panther",
    "parrot",
    "peacock",
    "pelican",
    "penguin",
    "pigeon",
    "pony",
    "poodle",
    "porcupine",
    "prawn",
    "puffin",
    "puma",
    "python",
    "rabbit",
    "raccoon",
    "raven",
    "rooster",
    "salamander",
    "salmon",
    "scallop",
    "scorpion",
    "seahorse",
    "shark",
    "sheep",
    "snail",
    "snake",
    "sparrow",
    "spider",
    "squid",
    "squirrel",
    "starfish",
    "stingray",
    "stork",
    "swan",
    "swordfish",
    "tern",
    "terrier",
    "tiger",
    "toucan",
    "trout",
    "tuna",
    "turkey",
    "turtle",
    "viper",
    "vulture",
    "wallaby",
    "walrus",
    "whale",
    "wildcat",
    "wolf",
    "wombat",
    "yak",
    "zebra",
  ]
}

variable "dashboard_service_url" {
  default     = "https://github.com/hashicorp/demo-consul-101/releases/download/0.0.1/dashboard-service_linux_amd64.zip"
  description = "Demo web app for Consul course"
}

variable "counting_service_url" {
  default     = "https://github.com/hashicorp/demo-consul-101/releases/download/0.0.1/counting-service_linux_amd64.zip"
  description = "Demo data service JSON API for Consul course"
}

