data "aws_iam_roles" "bootstrap_roles" {

  for_each   = local.role_name_regex_by_type
  name_regex = each.value

}

# Hard fail if we didn't get exactly 1 match per role type.
resource "terraform_data" "validate_bootstrap_roles" {

  for_each = data.aws_iam_roles.bootstrap_roles

  input = {
    role_type = each.key
    matches  = length( each.value.arns )
  }

  lifecycle {
    precondition {
      condition     = length( each.value.names ) == 1
      error_message = "Expected exactly 1 IAM role match for '${ each.key }' in accountId=${ var.accountId } region=${ var.region }. Found ${ length( each.value.names ) }: ${ join( ", ", each.value.names ) }"
    }
  }

}

# Construct policies based upon the discovered role ARNs.
locals {

  role_arn_by_type = {
    for role_type, roles_data in data.aws_iam_roles.bootstrap_roles :
      role_type => (
        length( roles_data.arns ) == 1
          ? one( tolist( roles_data.arns ) )
          : null
      )
  }

  role_arns_by_label = {
    for role_label, role_types in local.role_types_by_label :
      role_label => distinct(
        compact( [ for role_type in role_types : local.role_arn_by_type[ role_type ] ] )
      )
  }

}

data "aws_iam_policy_document" "this" {

  for_each = local.role_arns_by_label

  statement {
    sid = "AssumeCdkBootstrap${ title(each.key) }Roles"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
    resources = each.value
  }
}

resource "aws_iam_policy" "cdk_assumption" {

  depends_on = [ terraform_data.validate_bootstrap_roles ]

  for_each = data.aws_iam_policy_document.this

  name        = "cdk-${var.bootstrap_qualifier != null ? var.bootstrap_qualifier : "default"}-assume-${each.key}-roles-policy"
  path        = "/"
  description = "Assume policy for ${each.key} roles in CDK bootstrap stack"

// tags

  policy = each.value.json
}