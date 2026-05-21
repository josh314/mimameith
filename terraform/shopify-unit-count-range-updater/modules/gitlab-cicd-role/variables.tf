variable "aws_account_id" {
  description = "The AWS account ID where the GitLab CI/CD role will be created"
  type = string
}

variable "gitlab_group_name" {
  description = "The name of the GitLab group where the project resides"
  type = string
}

variable "gitlab_project_name" {
  description = "The name of the GitLab project"
  type = string
}

variable "environment" {
  description = "The environment for which this role is being created (e.g. dev, staging, prod)"
  type = string
}

variable "policies_by_role_type" {
  description = "A map of role types to lists of IAM policy ARNs to attach to the role"
  type = map(object({
    arn = string
  }))
}
