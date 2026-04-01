packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.6"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = "~> 1"
      source = "github.com/hashicorp/ansible"
    }
  }
}

variable "version" {
  type = string
}

variable "build_sha" {
  type = string
  default = "000000"
}

variable "mimameith_version" {
  type = string
  default = ""
}

variable "ansible_roles_sha" {
  type = string
  default = "000000"
}

variable "ansible_roles_version" {
  type = string
  default = ""
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {

  ami_name      = "lot-commander-app-server-${var.version}-${var.build_sha}-${local.timestamp}"
  instance_type = "m8a.large"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical's AWS account ID
  }


  ssh_username = "ubuntu"
  ssh_interface = "public_ip" # or private_ip depending on your setup
  communicator = "ssh"


  # enforces imdsv2 support on the running instance being provisioned by Packer
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 1
  }
  imds_support  = "v2.0" # enforces imdsv2 support on the resulting AMI

  tags = {
    Name                  = "lot-commander-app-server"
    app_version           = var.version
    build_sha             = var.build_sha
    mimameith_version     = var.mimameith_version
    ansible_roles_sha     = var.ansible_roles_sha
    ansible_roles_version = var.ansible_roles_version
    os                    = "ubuntu-22.04"
  }

}

build {
  name = "ubuntu-ansible"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "ansible" {
    playbook_file = "../../ansible/playbooks/app.yml"
    user = "ubuntu" # this sets the ansible_user variable, otherwise defaults to local user

    groups = [
      "app_servers",
    ]

    extra_arguments = [
      "--extra-vars", "@../../ansible/extra-vars.yml",
      "--vault-password-file", "../../ansible/password",
      "--verbose",

      "-e", "lot_commander__application_repository_version=${var.version}",
      "-e", "db_host=ehdb-internal.wholesaleninjas.com",
      "-e", "hosted_zone=wholesaleninjas.com",
    ]
  }
}