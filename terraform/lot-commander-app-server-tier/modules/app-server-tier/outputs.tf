output "alb_dns_name" {
  description = "ALB DNS name — use this to validate the stack before DNS cutover"
  value       = aws_lb.main.dns_name
}

output "app_server_subnet_id" {
  value = aws_subnet.app_servers.id
}

output "launch_template_id" {
  value = aws_launch_template.app.id
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}
