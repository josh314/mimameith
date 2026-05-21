output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "cdk_role_assumption_policies" {
  value = module.cdk_role_assumption_policies.this
}