# Mímameith

Infrastructure-as-code for internal Expresshop operations: Ansible playbooks provision EC2 app/DB servers, Terraform manages AWS resources per-stack, Packer bakes AMIs. See `README.md` for the project name's etymology (being refreshed separately — don't rely on it for technical accuracy yet).

## Environment setup

- Playbooks reference custom local roles (`nginx`, `lot_commander`, `pm2_app_service`, `cleanup`, etc.) that live in a **sibling repo**, not this one. Clone it next to this repo: `../ansible-roles` relative to `mimameith/`. `deploy-lot-commander.sh` defaults `ANSIBLE_ROLES_DIR` to that path (override with the env var of the same name).
- Third-party roles (`geerlingguy.nodejs`, etc.) come from Galaxy via `ansible/requirements.yml` — install with `ansible-galaxy install -r requirements.yml`.
- Ansible vault password file expected at `ansible/password` (gitignored).

## Repository layout

- `ansible/` — playbooks provisioning EC2 instances: `mongo-server.yml`, `mongo-backup.yml`, `load-balancer.yml`/`load-balancer-client.yml`, `manifest-service.yml`, `product-data-cache-updater-server.yml`, `shopify-data-dump-server.yml`, `shopify-mailchimp-campaigner-server.yml`, `cronbox.yml`/`ec2-cronbox.yml`, plus `app.yml`/`app-client.yml` (legacy lot-commander — see Gotchas). Vault-encrypted secrets in `ansible/secrets.yml`.
- `terraform/<stack>/` — one directory per Terraform-managed stack, each with `environments/<env>/` (root modules, own state) and `modules/`. Current stacks:
  - `aws-gitlab-oidc-provider` — GitLab OIDC trust + IAM roles for CI (no static AWS credentials)
  - `shopify-unit-count-range-updater` — WIP app stack, uses the OIDC-based GitLab CI role pattern
- `legacy/terraform/lot-commander-app-server-tier` — retired ASG/ALB Terraform for lot-commander (see Gotchas).
- `packer/app-server/template.pkr.hcl`, `deploy-lot-commander.sh` — legacy lot-commander AMI build/deploy tooling, no longer the live deploy path (see Gotchas).
- `__notes/` — gitignored (`__*` pattern) scratch/todo files, not committed docs, not a source of truth.

## Commands

### Ansible secrets
```bash
ansible-vault view ansible/secrets.yml
ansible-vault edit ansible/secrets.yml
```

### Terraform (per stack/env)
```bash
cd terraform/<stack>/environments/<env>
terraform init && terraform plan && terraform apply
```
Each environment has its own S3 backend key (bucket `tf-state-<account-id>-us-east-1`) with `use_lockfile = true` (native S3 locking — no DynamoDB table).

## Gotchas

- **lot-commander's app-server infra has fully moved to ECS, managed in a separate project outside this repo.** The old ASG/ALB Terraform here was retired to `legacy/terraform/lot-commander-app-server-tier` (commit `0a3b70b`). `deploy-lot-commander.sh`, `packer/app-server/`, and `ansible/playbooks/app.yml`/`app-client.yml` are leftovers from that path (not yet moved/deleted) and are **not** the live deploy mechanism for lot-commander anymore — `deploy-lot-commander.sh`'s `TF_DIR` still points at the now-removed `terraform/lot-commander-app-server-tier`, so it will error if run; that's expected, not a bug to fix here.
- `ansible/run-playbooks.sh` (the `--vendor` deploy path) is stale/broken: it references `playbooks/ec2-stack-vendor.yml` and `vendors.txt`, neither of which exist (the real file is `playbooks/ec2-stack-client.yml`). Don't use `--vendor` without fixing this first.
- Two unrelated "sandbox" namings exist: Ansible has `ansible/inventory/sandbox`; Terraform environments are named after AWS account codenames (`sandbox-autarch`, `wazuezoom`) which have nothing to do with the Ansible one.
