# define the trust policy that allows GitLab CI/CD to assume the role
data "aws_iam_policy_document" "gitlab_cicd_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:oidc-provider/gitlab.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "gitlab.com:sub"
      values   = [
        "project_path:${var.gitlab_group_name}/${var.gitlab_project_name}:ref_type:branch:ref:${var.environment}*",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "gitlab.com:aud"
      values   = [
        "sts.amazonaws.com",
      ]
    }
  }
}

# create IAM role for given project that GitLab CI/CD can assume
resource "aws_iam_role" "gitlab_cicd_role" {

  for_each = local.role_data

  name               = each.value.name
  assume_role_policy = data.aws_iam_policy_document.gitlab_cicd_assume_role_policy.json
  description        = "IAM ${each.key} role for GitLab CI/CD for project ${var.gitlab_project_name} in environment ${var.environment}"
  path               = "/"

  # tags = var.tags
}

# attach policies to the role
resource "aws_iam_role_policy_attachment" "gitlab_cicd_role_policy_attachment" {

  for_each = local.role_data

  role       = aws_iam_role.gitlab_cicd_role[each.key].name
  policy_arn = each.value.policy_arn

}

# create Gitlab CICD variable to store the role ARN
resource "gitlab_project_variable" "gitlab_cicd_role_arn" {

  for_each = local.role_data

  project       = "${var.gitlab_group_name}/${var.gitlab_project_name}"
  key           = each.value.gitlab_variable_key
  value         = aws_iam_role.gitlab_cicd_role[each.key].arn
  protected     = ( var.environment == "prod" ) ? true : false
  masked        = true
  environment_scope = var.environment
}