output "debug_bootstrap_roles" {
  value = data.aws_iam_roles.bootstrap_roles
}

output "debug_role_name_regex_by_type" {
  value = local.role_name_regex_by_type
}

output "this" {
  value = resource.aws_iam_policy.cdk_assumption
}