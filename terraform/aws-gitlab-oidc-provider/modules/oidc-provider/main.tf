data "tls_certificate" "gitlab" {
  url = var.gitlab_tls_url
}

locals {
  thumbprints = distinct(
    concat(
      [data.tls_certificate.gitlab.certificates[0].sha1_fingerprint],
      var.additional_thumbprints
    )
  )
}

resource "aws_iam_openid_connect_provider" "gitlab" {
  url             = var.gitlab_oidc_issuer_url
  client_id_list  = [var.audience]
  thumbprint_list = local.thumbprints

  lifecycle {
    prevent_destroy = true
  }
}
