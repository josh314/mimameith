module "stack" {
  source = "../../modules/stack"

  providers = {
    gitlab = gitlab
  }
}