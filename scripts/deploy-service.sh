#!/usr/bin/env bash
# Rolls one ECS service to a new image and waits until it is stable.
#
# Usage: deploy-service.sh <aws-region> <cluster> <service> <image> <work-file-prefix>
#
# It starts from the LATEST revision of the service's task definition family, not from the revision
# the service currently points at. That way any environment change Terraform made (for example the
# database host or the region cookie settings) is picked up, and only the image is swapped.
set -euo pipefail

REGION="$1"
CLUSTER="$2"
SERVICE="$3"
IMAGE="$4"
PREFIX="$5"

CURRENT=$(aws ecs describe-services --region "${REGION}" --cluster "${CLUSTER}" --services "${SERVICE}" \
  --query 'services[0].taskDefinition' --output text)
FAMILY="${CURRENT##*/}"
FAMILY="${FAMILY%:*}"

aws ecs describe-task-definition --region "${REGION}" --task-definition "${FAMILY}" \
  --query 'taskDefinition' > "${PREFIX}.json"

jq --arg image "${IMAGE}" '
  .containerDefinitions[0].image = $image
  | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)
' "${PREFIX}.json" > "${PREFIX}-updated.json"

NEW_TASK_DEFINITION=$(aws ecs register-task-definition --region "${REGION}" \
  --cli-input-json "file://${PREFIX}-updated.json" \
  --query 'taskDefinition.taskDefinitionArn' --output text)

aws ecs update-service --region "${REGION}" --cluster "${CLUSTER}" --service "${SERVICE}" \
  --task-definition "${NEW_TASK_DEFINITION}" --force-new-deployment >/dev/null
aws ecs wait services-stable --region "${REGION}" --cluster "${CLUSTER}" --services "${SERVICE}"
echo "${SERVICE} is running ${IMAGE}"