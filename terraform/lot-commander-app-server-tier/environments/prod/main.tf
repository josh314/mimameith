provider "aws" {
  region = "us-east-1"
}

# ALB requires subnets in at least 2 AZs. Use the existing default subnets
# from the VPC (one per AZ) — they already have routes to the IGW.
# The ASG instances live only in the new /26 subnet (us-east-1a).
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = ["vpc-39092a5d"]
  }
  filter {
    name   = "defaultForAz"
    values = ["true"]
  }
}

module "app_server_tier" {
  source = "../../modules/app-server-tier"

  app_name    = "lot-commander"
  environment = "prod"

  vpc_id            = "vpc-39092a5d"
  availability_zone = "us-east-1a"
  subnet_cidr       = "172.31.112.0/26"

  alb_subnet_ids = data.aws_subnets.default.ids

  additional_security_group_ids = [
    "sg-0d79155d77efa9078", # EHDB access
  ]

  ami_ssm_parameter_name = "/prod/lot-commander/app-server/ami-id"
  instance_type          = "t3a.micro"
  app_port               = 9000

  domain_name      = "lot-commander.wholesaleninjas.com"
  hosted_zone_name = "wholesaleninjas.com."

  # Set to true when ready to cut over from the existing EC2 load balancer
  create_dns_record = false

  s3_app_buckets = [
    "expresshop-documents",
    "expresshop-manifests",
    "expresshop-product-data-jobs",
    "lot-images",
    "lot-videos",
  ]

  asg_desired_capacity = 1
  asg_min_size         = 1
  asg_max_size         = 1
}

output "alb_dns_name" {
  description = "Validate the new stack against this URL before setting create_dns_record = true"
  value       = module.app_server_tier.alb_dns_name
}

output "asg_name" {
  value = module.app_server_tier.asg_name
}
