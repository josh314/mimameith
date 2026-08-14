variable "app_name" {
  description = "Application name, used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. prod, sandbox)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to deploy into"
  type        = string
}

variable "availability_zone" {
  description = "AZ for the app server subnet and ASG instances"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the new app server subnet"
  type        = string
}

variable "alb_subnet_ids" {
  description = "Subnet IDs for the ALB — must span at least 2 AZs for internet-facing ALBs"
  type        = list(string)
}

variable "additional_security_group_ids" {
  description = "Security group IDs to attach to ASG instances in addition to the managed app-server SG"
  type        = list(string)
  default     = []
}

variable "instance_type" {
  description = "EC2 instance type for ASG instances"
  type        = string
  default     = "t3a.micro"
}

variable "ami_ssm_parameter_name" {
  description = "SSM parameter path storing the current app AMI ID"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 9000
}

variable "health_check_path" {
  description = "HTTP path the ALB uses for target health checks"
  type        = string
  default     = "/api/health"
}

variable "domain_name" {
  description = "Full domain name for the ALB"
  type        = string
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name"
  type        = string
}

variable "create_dns_record" {
  description = "Set to true when ready to cut over DNS to the ALB. Keep false until the new stack is validated."
  type        = bool
  default     = false
}

variable "s3_app_buckets" {
  description = "S3 bucket names the app needs read/write/list access to (no bucket create/delete)"
  type        = list(string)
}

variable "asg_desired_capacity" {
  type    = number
  default = 1
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 1
}
