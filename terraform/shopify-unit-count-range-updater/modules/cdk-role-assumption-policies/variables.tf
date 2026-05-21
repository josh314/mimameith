variable "accountId" {
  type = string
}

variable "region" {
  type = string
}

# Optional: if you *want* to pin to a specific qualifier (e.g. "hnb659fds"),
# set this. If null, we match any qualifier.
variable "bootstrap_qualifier" {
  type    = string
  default = null
}
