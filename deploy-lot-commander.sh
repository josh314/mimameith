#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: ./deploy-lot-commander.sh <version> [-e|--env <dev|prod>]" >&2
  exit 1
}

VERSION="${1:?$(usage)}"
shift

ENV=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--env)
      ENV="${2:?--env requires a value}"
      shift 2
      ;;
    *) usage ;;
  esac
done

if [[ -z "$ENV" ]]; then
  echo "WARNING: --env not specified, defaulting to dev" >&2
  read -r -p "Continue with dev? [y/N] " response </dev/tty
  if [[ ! "$response" =~ ^[yY]$ ]]; then
    echo "Aborting." >&2
    exit 1
  fi
  ENV="dev"
fi

if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "ERROR: invalid environment '$ENV' — must be dev or prod" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_ROLES_DIR="${ANSIBLE_ROLES_DIR:-"$(dirname "$REPO_ROOT")/ansible-roles"}"
PACKER_DIR="$REPO_ROOT/packer/app-server"
TF_DIR="$REPO_ROOT/terraform/lot-commander-app-server-tier/environments/$ENV"
SSM_PARAMETER="/$ENV/lot-commander/app-server/ami-id"
REGION="us-east-1"

SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9._-]+)?$'

# ── Repo checks ───────────────────────────────────────────────────────────────

prompt_continue() {
  echo "WARNING: $1" >&2
  read -r -p "Continue anyway? [y/N] " response </dev/tty
  if [[ ! "$response" =~ ^[yY]$ ]]; then
    echo "Aborting." >&2
    exit 1
  fi
}

# Writes sha and tag into named variables in the caller's scope (avoids
# subshell so that prompt_continue can read from the terminal).
check_repo() {
  local name="$1"
  local dir="$2"
  local sha_var="$3"
  local tag_var="$4"
  local sha tag

  sha=$(git -C "$dir" rev-parse --short HEAD)

  if ! git -C "$dir" diff --quiet || ! git -C "$dir" diff --cached --quiet; then
    prompt_continue "$name has uncommitted changes — build may not be reproducible"
  fi

  tag=$(git -C "$dir" tag --points-at HEAD | grep -E "$SEMVER_RE" | sort -V | tail -1)

  if [[ -z "$tag" ]]; then
    prompt_continue "$name HEAD ($sha) is not at a semver tag"
    tag="NONE"
  fi

  printf -v "$sha_var" '%s' "$sha"
  printf -v "$tag_var" '%s' "$tag"
}

check_repo "mimameith"     "$REPO_ROOT"          BUILD_SHA   BUILD_TAG
check_repo "ansible-roles" "$ANSIBLE_ROLES_DIR"  AR_SHA      AR_TAG

# ── Build AMI ─────────────────────────────────────────────────────────────────

echo "==> Building AMI for lot-commander $VERSION [$ENV] (sha: $BUILD_SHA, tag: $BUILD_TAG)..."
cd "$PACKER_DIR"

packer_log=$(mktemp)
trap 'rm -f "$packer_log"' EXIT

packer build \
  -machine-readable \
  -var "environment=$ENV" \
  -var "version=$VERSION" \
  -var "build_sha=$BUILD_SHA" \
  -var "mimameith_version=$BUILD_TAG" \
  -var "ansible_roles_sha=$AR_SHA" \
  -var "ansible_roles_version=$AR_TAG" \
  template.pkr.hcl | tee "$packer_log"

AMI_ID=$(grep ',artifact,0,id,' "$packer_log" | cut -d, -f6 | cut -d: -f2)

if [[ -z "$AMI_ID" ]]; then
  echo "ERROR: failed to extract AMI ID from packer output" >&2
  exit 1
fi

echo ""
echo "==> AMI built: $AMI_ID"

# ── Update SSM ────────────────────────────────────────────────────────────────

echo "==> Updating SSM parameter $SSM_PARAMETER..."
aws ssm put-parameter \
  --region "$REGION" \
  --name "$SSM_PARAMETER" \
  --value "$AMI_ID" \
  --type "String" \
  --overwrite \
  --no-cli-pager

# ── Deploy ────────────────────────────────────────────────────────────────────

echo "==> Running terraform apply..."
cd "$TF_DIR"

# Check before apply so we know whether to trigger an instance refresh after
terraform state list 2>/dev/null | grep -q 'aws_autoscaling_group' && ASG_EXISTS=true || ASG_EXISTS=false

terraform apply

ASG_NAME=$(terraform output -raw asg_name)

if $ASG_EXISTS; then
  echo "==> Starting instance refresh on $ASG_NAME..."
  aws autoscaling start-instance-refresh \
    --region "$REGION" \
    --auto-scaling-group-name "$ASG_NAME" \
    --preferences '{"MinHealthyPercentage": 100, "MaxHealthyPercentage": 200}' \
    --no-cli-pager
  echo ""
  echo "==> Deploy complete: lot-commander $VERSION ($AMI_ID)"
  echo "    Instance refresh is now in progress — monitor in the EC2 console."
else
  echo ""
  echo "==> Deploy complete: lot-commander $VERSION ($AMI_ID)"
fi
