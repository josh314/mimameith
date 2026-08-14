locals {
  name_prefix = "${var.environment}-${var.app_name}"
}

# ── Data Sources ──────────────────────────────────────────────────────────────

data "aws_ssm_parameter" "ami" {
  name = var.ami_ssm_parameter_name
}

data "aws_route53_zone" "main" {
  name         = var.hosted_zone_name
  private_zone = false
}

# Associate the new subnet with the VPC's main route table (has the IGW route)
data "aws_route_table" "main" {
  vpc_id = var.vpc_id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# ── Networking ────────────────────────────────────────────────────────────────

resource "aws_subnet" "app_servers" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-app-servers"
    env  = var.environment
  }
}

resource "aws_route_table_association" "app_servers" {
  subnet_id      = aws_subnet.app_servers.id
  route_table_id = data.aws_route_table.main.id
}

# ── Security Groups ───────────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb"
  description = "ALB: allow inbound HTTP/HTTPS from internet, egress to app servers only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-alb"
    env  = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP (redirect to HTTPS)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app_servers" {
  security_group_id = aws_security_group.alb.id
  description       = "To app servers on app port"
  from_port         = var.app_port
  to_port           = var.app_port
  ip_protocol       = "tcp"
  cidr_ipv4         = var.subnet_cidr
}

resource "aws_security_group" "app_servers" {
  name        = "${local.name_prefix}-app-servers"
  description = "App servers: allow inbound from ALB on app port only; no SSH"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-app-servers"
    env  = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_servers_from_alb" {
  security_group_id            = aws_security_group.app_servers.id
  description                  = "From ALB"
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

# Unrestricted egress for outbound API calls, SSM, package updates, etc.
resource "aws_vpc_security_group_egress_rule" "app_servers_egress" {
  security_group_id = aws_security_group.app_servers.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ── IAM ───────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "app_servers" {
  name = "${local.name_prefix}-app-servers"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.name_prefix}-app-servers"
    env  = var.environment
  }
}

# Enables SSM Session Manager — replaces SSH access
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app_servers.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "s3" {
  name = "s3-app-buckets"
  role = aws_iam_role.app_servers.name

  policy = jsonencode({
    Version = "2012-10-17"
    # TODO: tighten to least-privilege once S3 usage is fully audited
    Statement = [
      {
        Sid      = "FullAccessAppBuckets"
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = flatten([
          for b in var.s3_app_buckets : [
            "arn:aws:s3:::${b}",
            "arn:aws:s3:::${b}/*",
          ]
        ])
      },
    ]
  })
}

resource "aws_iam_instance_profile" "app_servers" {
  name = "${local.name_prefix}-app-servers"
  role = aws_iam_role.app_servers.name
}

# ── ACM Certificate ───────────────────────────────────────────────────────────
# The validation CNAME record does not affect the existing A record for this
# domain — it is safe to apply before the DNS cutover.

resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = local.name_prefix
    env  = var.environment
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# ── Load Balancer ─────────────────────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.alb_subnet_ids

  tags = {
    Name = "${var.app_name}-alb"
    env  = var.environment
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${local.name_prefix}-app"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.app_name}-app"
    env  = var.environment
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.main.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ── Launch Template ───────────────────────────────────────────────────────────

resource "aws_launch_template" "app" {
  name          = "${local.name_prefix}-app"
  image_id      = data.aws_ssm_parameter.ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.app_servers.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = concat(
      [aws_security_group.app_servers.id],
      var.additional_security_group_ids
    )
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  # Each terraform apply that changes the AMI (or any other field) creates a
  # new LT version and promotes it to default. The ASG uses $Default, so the
  # next instance refresh will pick it up automatically.
  update_default_version = true

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.app_name}-app"
      env  = var.environment
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.app_name}-app"
      env  = var.environment
    }
  }
}

# ── Auto Scaling Group ────────────────────────────────────────────────────────

resource "aws_autoscaling_group" "app" {
  name                      = "${local.name_prefix}-app"
  vpc_zone_identifier       = [aws_subnet.app_servers.id]
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  desired_capacity = var.asg_desired_capacity
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Default"
  }

  # Triggered automatically when the launch template default version changes
  # (i.e. on each app deploy). max_healthy_percentage = 200 means AWS launches
  # the replacement first, waits for it to pass health checks, then terminates
  # the old one — zero downtime.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      max_healthy_percentage = 200
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "env"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "org"
    value               = "wholesale-ninjas"
    propagate_at_launch = true
  }

  tag {
    key                 = "tier"
    value               = "app"
    propagate_at_launch = true
  }

  tag {
    key                 = "stack"
    value               = "lot-commander"
    propagate_at_launch = true
  }


}

# ── Route53 ───────────────────────────────────────────────────────────────────
# CUTOVER STEP: set create_dns_record = true only after validating the new
# stack via the ALB DNS name directly. This will replace the existing A record.

resource "aws_route53_record" "app" {
  count = var.create_dns_record ? 1 : 0

  zone_id         = data.aws_route53_zone.main.zone_id
  name            = var.domain_name
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
