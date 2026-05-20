variable "gitlab_oidc_issuer_url" {
  description = "OIDC issuer URL (iss) used by GitLab"
  type        = string
  default     = "https://gitlab.com"
}

variable "gitlab_tls_url" {
  description = "TLS endpoint used only to retrieve the certificate thumbprint"
  type        = string
  # Avoid using https scheme because the Hashicorp TLS provider has started following redirects starting v4.
  # See https://github.com/hashicorp/terraform-provider-tls/issues/249
  default = "tls://gitlab.com:443"
}

variable "audience" {
  description = "OIDC audience value"
  type        = string
  default     = "sts.amazonaws.com"
}

variable "additional_thumbprints" {
  type    = list(string)
  default = []
}
