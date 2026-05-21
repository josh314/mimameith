terraform {
  required_version = ">= 1.14"

  backend "s3" {
    region       = "us-east-1"
    bucket       = "tf-state-476114126879-us-east-1"
    key          = "shopify-unit-count-range-updater.tfstate"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 18.0"
    }
  }
}

provider "gitlab" {
  base_url = "https://gitlab.com/api/v4/"
}