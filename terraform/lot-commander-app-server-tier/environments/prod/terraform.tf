terraform {
  required_version = ">= 1.14"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tf-state-141569191774-us-east-1"
    key            = "lot-commander-app-server-tier.tfstate"
    use_lockfile   = true
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
