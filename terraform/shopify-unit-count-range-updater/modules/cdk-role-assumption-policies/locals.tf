locals {

  role_types_by_label = {
    "deploy" = [
      "deploy",
      "file-publishing",
      "image-publishing",
    ]
    "lookup" = [
      "lookup",
    ]
  }

  qualifier_pattern = (var.bootstrap_qualifier != null) ? var.bootstrap_qualifier : "[^-]+"

  role_name_regex_by_type = merge( [
    for role_labels, role_types in local.role_types_by_label : {
      for role_type in role_types : role_type => "^cdk-${local.qualifier_pattern}-${role_type}-role-${var.accountId}-${var.region}$"
    }
  ]... )

}
