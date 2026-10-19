#!/usr/bin/env bash
# Shared helpers for the release scripts. This file is sourced, never run directly.
#
# The project has two "regions": blue = us-east-1, green = eu-north-1.

# aws region for a region name (blue|green)
region_of() {
  case "$1" in
    blue) echo "us-east-1" ;;
    green) echo "eu-north-1" ;;
    *)
      echo "Unknown region name '$1' (expected blue or green)" >&2
      return 1
      ;;
  esac
}

# Load balancer name for a region name (blue|green)
alb_name_of() {
  case "$1" in
    blue) echo "${BLUE_ALB_NAME:?BLUE_ALB_NAME is not set}" ;;
    green) echo "${GREEN_ALB_NAME:?GREEN_ALB_NAME is not set}" ;;
    *)
      echo "Unknown region name '$1' (expected blue or green)" >&2
      return 1
      ;;
  esac
}

# Prints "<alb-dns-name><TAB><alb-hosted-zone-id>" for a region name.
# Fails loudly if the load balancer does not exist, so a missing region never turns into a half-built DNS record.
alb_alias() {
  local out
  out=$(aws elbv2 describe-load-balancers \
    --region "$(region_of "$1")" \
    --names "$(alb_name_of "$1")" \
    --query 'LoadBalancers[0].[DNSName,CanonicalHostedZoneId]' \
    --output text) || return 1
  if [ -z "${out}" ] || [[ "${out}" == None* ]]; then
    echo "Load balancer $(alb_name_of "$1") was not found in $(region_of "$1")" >&2
    return 1
  fi
  echo "${out}"
}