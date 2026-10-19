#!/usr/bin/env bash
# Adds or removes the "stay in your region" redirect rules on ONE region's load balancer.
# The pipeline turns them on when the canary starts and off when it ends (promote or rollback).
#
# Why this exists: Route 53 weighted routing picks a region on every DNS lookup, so a visitor
# can bounce between the old and new region. Each region's nginx tags visitors with a cookie
# (bg_region=blue|green). While the canary runs, two rules on this load balancer act only on page
# loads of the weighted hostname (Host = RECORD, path "/"):
#
#   priority 10  cookie says the OTHER region   -> redirect to <other>.RECORD   (return to your region)
#   priority 11  anything else                  -> redirect to <this>.RECORD    (pin the session here)
#
# After the redirect the visitor is on a fixed hostname, so the page and every /api call stay in one
# region. API calls are never redirected (a redirect would turn a POST into a GET).
#
# Usage: canary-pin.sh <enable|disable> <this-region> <other-region>
# Needs: ROUTE53_RECORD_NAME, BLUE_ALB_NAME, GREEN_ALB_NAME
set -euo pipefail

# shellcheck source=scripts/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ACTION="${1:?usage: canary-pin.sh <enable|disable> <this-region> <other-region>}"
THIS="${2:?}"
OTHER="${3:?}"
RECORD="${ROUTE53_RECORD_NAME:?ROUTE53_RECORD_NAME is not set}"

AWS_REGION_NAME="$(region_of "${THIS}")"
ALB_NAME="$(alb_name_of "${THIS}")"
PRIORITY_COOKIE=10
PRIORITY_HOST=11

LB_ARN=$(aws elbv2 describe-load-balancers --region "${AWS_REGION_NAME}" --names "${ALB_NAME}" \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
LISTENER_ARN=$(aws elbv2 describe-listeners --region "${AWS_REGION_NAME}" --load-balancer-arn "${LB_ARN}" \
  --query 'Listeners[?Port==`80`].ListenerArn | [0]' --output text)
if [ -z "${LISTENER_ARN}" ] || [ "${LISTENER_ARN}" = "None" ]; then
  echo "No port 80 listener found on ${ALB_NAME}" >&2
  exit 1
fi

# Always start clean, so running this twice never fails on "priority already in use".
OLD_RULES=$(aws elbv2 describe-rules --region "${AWS_REGION_NAME}" --listener-arn "${LISTENER_ARN}" \
  --query "Rules[?Priority=='${PRIORITY_COOKIE}' || Priority=='${PRIORITY_HOST}'].RuleArn" --output text)
for rule_arn in ${OLD_RULES}; do
  [ "${rule_arn}" = "None" ] && continue
  aws elbv2 delete-rule --region "${AWS_REGION_NAME}" --rule-arn "${rule_arn}"
done

if [ "${ACTION}" = "disable" ]; then
  echo "Canary pin rules removed from ${ALB_NAME}"
  exit 0
fi
if [ "${ACTION}" != "enable" ]; then
  echo "Action must be enable or disable" >&2
  exit 1
fi

redirect_action() { # host
  jq -nc --arg host "$1" '[{Type: "redirect", RedirectConfig: {Protocol: "HTTP", Port: "80", Host: $host, Path: "/#{path}", Query: "#{query}", StatusCode: "HTTP_302"}}]'
}

# Both rules only look at page loads of the weighted hostname.
page_load_conditions=$(jq -nc --arg host "${RECORD}" '[
  {Field: "host-header", HostHeaderConfig: {Values: [$host]}},
  {Field: "path-pattern", PathPatternConfig: {Values: ["/"]}}
]')
cookie_conditions=$(jq -c --arg cookie "*bg_region=${OTHER}*" \
  '. + [{Field: "http-header", HttpHeaderConfig: {HttpHeaderName: "Cookie", Values: [$cookie]}}]' <<<"${page_load_conditions}")

# Rule 1: visitor already belongs to the other region -> send them back there.
aws elbv2 create-rule --region "${AWS_REGION_NAME}" --listener-arn "${LISTENER_ARN}" \
  --priority "${PRIORITY_COOKIE}" \
  --conditions "${cookie_conditions}" \
  --actions "$(redirect_action "${OTHER}.${RECORD}")" >/dev/null

# Rule 2: everyone else -> pin them to this region's own hostname.
aws elbv2 create-rule --region "${AWS_REGION_NAME}" --listener-arn "${LISTENER_ARN}" \
  --priority "${PRIORITY_HOST}" \
  --conditions "${page_load_conditions}" \
  --actions "$(redirect_action "${THIS}.${RECORD}")" >/dev/null

echo "Canary pin rules active on ${ALB_NAME} (${THIS}); other region = ${OTHER}"