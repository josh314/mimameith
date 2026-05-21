locals {

  role_data = {
    for role_type, policy in var.policies_by_role_type : role_type => {
      name = "${var.gitlab_project_name}-cicd-${var.environment}-${role_type}-role"
      policy_arn = policy.arn
      gitlab_variable_key = upper(replace("${var.environment}_${role_type}_ROLE_ARN", "-", "_"))
    }
  }

}