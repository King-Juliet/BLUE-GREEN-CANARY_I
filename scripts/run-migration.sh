#!/usr/bin/env bash
# Runs the database migration as a one-off Fargate task and fails if it fails.
#
# Usage: run-migration.sh <region> <cluster> <backend-service> <migrate-task-family> <backend-image>
#
# The migrate task definition (created by Terraform) holds a placeholder image,
# so we register a new revision pointing at THIS release's backend image first.
set -euo pipefail

REGION="$1"
CLUSTER="$2"
BACKEND_SERVICE="$3"
FAMILY="$4"
IMAGE="$5"

echo "Registering migrate task definition (${FAMILY}) with image ${IMAGE}"
aws ecs describe-task-definition --region "${REGION}" --task-definition "${FAMILY}" \
  --query 'taskDefinition' > migrate-task-definition.json

jq --arg image "${IMAGE}" '
  .containerDefinitions[0].image = $image
  | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)
' migrate-task-definition.json > migrate-task-definition-updated.json

TASK_DEFINITION_ARN=$(aws ecs register-task-definition --region "${REGION}" \
  --cli-input-json "file://migrate-task-definition-updated.json" \
  --query 'taskDefinition.taskDefinitionArn' --output text)

# Reuse the backend service's subnets and security group (they can already reach RDS, SSM and ECR).
NETWORK_CONFIGURATION=$(aws ecs describe-services --region "${REGION}" --cluster "${CLUSTER}" \
  --services "${BACKEND_SERVICE}" \
  --query 'services[0].networkConfiguration.awsvpcConfiguration' --output json | jq -c '{awsvpcConfiguration: .}')

echo "Starting migration task"
RUN_OUTPUT=$(aws ecs run-task --region "${REGION}" --cluster "${CLUSTER}" --launch-type FARGATE \
  --task-definition "${TASK_DEFINITION_ARN}" --network-configuration "${NETWORK_CONFIGURATION}" --output json)
TASK_ARN=$(echo "${RUN_OUTPUT}" | jq -r '.tasks[0].taskArn // empty')

if [ -z "${TASK_ARN}" ]; then
  echo "ECS could not start the migration task:"
  echo "${RUN_OUTPUT}" | jq '.failures'
  exit 1
fi

TASK_ID="${TASK_ARN##*/}"
echo "Migration task ${TASK_ID} started, waiting for it to finish"
aws ecs wait tasks-stopped --region "${REGION}" --cluster "${CLUSTER}" --tasks "${TASK_ARN}"

EXIT_CODE=$(aws ecs describe-tasks --region "${REGION}" --cluster "${CLUSTER}" --tasks "${TASK_ARN}" \
  --query 'tasks[0].containers[0].exitCode' --output text)
STOPPED_REASON=$(aws ecs describe-tasks --region "${REGION}" --cluster "${CLUSTER}" --tasks "${TASK_ARN}" \
  --query 'tasks[0].stoppedReason' --output text)

# Show what the migration printed (needs logs:GetLogEvents; skipped quietly if not allowed).
LOG_GROUP=$(jq -r '.containerDefinitions[0].logConfiguration.options["awslogs-group"]' migrate-task-definition.json)
LOG_PREFIX=$(jq -r '.containerDefinitions[0].logConfiguration.options["awslogs-stream-prefix"]' migrate-task-definition.json)
CONTAINER_NAME=$(jq -r '.containerDefinitions[0].name' migrate-task-definition.json)
echo "----- migration log -----"
aws logs get-log-events --region "${REGION}" --log-group-name "${LOG_GROUP}" \
  --log-stream-name "${LOG_PREFIX}/${CONTAINER_NAME}/${TASK_ID}" \
  --query 'events[].message' --output text 2>/dev/null | tr '\t' '\n' || echo "(could not read logs - check CloudWatch group ${LOG_GROUP})"
echo "-------------------------"

if [ "${EXIT_CODE}" != "0" ]; then
  echo "Migration FAILED (exit code: ${EXIT_CODE}, reason: ${STOPPED_REASON}). Not deploying this region."
  exit 1
fi

echo "Migration finished successfully."