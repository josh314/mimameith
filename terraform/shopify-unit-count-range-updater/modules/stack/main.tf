data "aws_caller_identity" "current" {}

module "cdk_role_assumption_policies" {
  source = "../cdk-role-assumption-policies"
  accountId = data.aws_caller_identity.current.account_id
  region    = "us-east-1"
}

module "gitlab_cicd_role" {
  source = "../gitlab-cicd-role"

  providers = {
    gitlab = gitlab
  }

  policies_by_role_type = module.cdk_role_assumption_policies.this
  aws_account_id = data.aws_caller_identity.current.account_id
  gitlab_group_name   = "wazue"
  gitlab_project_name = "shopify-unit-count-range-updater"
  environment         = "dev"
}