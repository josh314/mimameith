output "oidc_provider_arn" {
  description = "ARN of the GitLab OIDC provider"
  value       = aws_iam_openid_connect_provider.gitlab.arn
}

output "oidc_provider_url" {
  description = "Issuer URL of the GitLab OIDC provider"
  value       = aws_iam_openid_connect_provider.gitlab.url
}
