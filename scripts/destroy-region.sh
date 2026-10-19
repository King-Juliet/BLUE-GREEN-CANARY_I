#!/usr/bin/env bash
# Destroys one region's stack (VPC, ALB, ECS, ECR, peering, ...). The shared database stack is NOT touched.
#
# Used by:
#   - the deploy workflow, automatically, after a canary has been promoted to 100%
#   - the "Destroy Idle Region" workflow, by hand
#
# It refuses to destroy the region that is currently active.
#
# Usage: destroy-region.sh <blue|green>
# Needs: TF_STATE_BUCKET, ACTIVE_REGION_PARAMETER, ROUTE53_ZONE_NAME, ROUTE53_RECORD_NAME, BLUE_ALB_NAME, GREEN_ALB_NAME
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
. "${SCRIPT_DIR}/common.sh"

TARGET="${1:?usage: destroy-region.sh <blue|green>}"
STATE_BUCKET="${TF_STATE_BUCKET:?TF_STATE_BUCKET is not set}"
ACTIVE_PARAMETER="${ACTIVE_REGION_PARAMETER:-/bluegreen-canary/deployment/active-region}"

case "${TARGET}" in
  blue) TF_DIR="infrastructure/us-east-1" ;;
  green) TF_DIR="infrastructure/eu-north-1" ;;
  *)
    echo "Region must be blue or green" >&2
    exit 1
    ;;
esac

ACTIVE=$(aws ssm get-parameter --region us-east-1 --name "${ACTIVE_PARAMETER}" \
  --query 'Parameter.Value' --output text 2>/dev/null || true)
if [ -z "${ACTIVE}" ]; then
  echo "No active region is recorded yet, so there is nothing safe to keep. Refusing to destroy ${TARGET}." >&2
  exit 1
fi
if [ "${ACTIVE}" = "${TARGET}" ]; then
  echo "${TARGET} is the ACTIVE region and serves live traffic. Refusing to destroy it." >&2
  exit 1
fi

echo "Active region: ${ACTIVE}. Destroying idle region: ${TARGET}"

# 1. DNS first, so nothing points at the load balancer we are about to delete.
bash "${SCRIPT_DIR}/canary-pin.sh" disable "${ACTIVE}" "${TARGET}"
bash "${SCRIPT_DIR}/route53.sh" retire "${TARGET}" "${ACTIVE}"

# 2. Then the infrastructure.
terraform -chdir="${TF_DIR}" init -input=false \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="key=${TARGET}/terraform.tfstate" \
  -backend-config="region=us-east-1"
terraform -chdir="${TF_DIR}" destroy -input=false -auto-approve

echo "Region ${TARGET} destroyed."