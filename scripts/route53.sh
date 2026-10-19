#!/usr/bin/env bash
# Owns every record inside the Route 53 zone. Terraform only owns the zone itself.
#
# Records managed here (RECORD = ROUTE53_RECORD_NAME, e.g. app.bluegreen-canary.test):
#   RECORD                 weighted alias records, one per live region (set identifiers blue-region / green-region)
#   blue.RECORD            fixed hostname for the blue region
#   green.RECORD           fixed hostname for the green region
#
# The fixed hostnames are what the canary cookie rules redirect visitors to (see canary-pin.sh).
# A hostname whose region is not running points at the region that IS running, so an old
# bookmark or an open browser tab never lands on a deleted load balancer.
#
# Usage:
#   route53.sh init <region>                              first release: <region> gets 100% of traffic
#   route53.sh split <region1> <region2> <weight1> <weight2>   weighted split between two live regions
#   route53.sh retire <old-region> <live-region>          remove old-region's weighted record, point its hostname at live-region
#
# Needs: ROUTE53_ZONE_NAME, ROUTE53_RECORD_NAME, BLUE_ALB_NAME, GREEN_ALB_NAME
set -euo pipefail

# shellcheck source=scripts/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ZONE_NAME="${ROUTE53_ZONE_NAME:?ROUTE53_ZONE_NAME is not set}"
RECORD="${ROUTE53_RECORD_NAME:?ROUTE53_RECORD_NAME is not set}"

ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "${ZONE_NAME}." \
  --query "HostedZones[?Name=='${ZONE_NAME}.'].Id | [0]" --output text | sed 's#.*/##')
if [ -z "${ZONE_ID}" ] || [ "${ZONE_ID}" = "None" ]; then
  echo "Hosted zone ${ZONE_NAME} was not found" >&2
  exit 1
fi

# One change for an alias A record. Weighted when a set identifier is given.
# args: action name set-identifier weight alb-dns alb-zone-id
alias_change() {
  jq -n --arg action "$1" --arg name "$2" --arg sid "$3" --arg weight "$4" --arg dns "$5" --arg zone "$6" '
    {
      Action: $action,
      ResourceRecordSet: (
        {Name: $name, Type: "A", AliasTarget: {DNSName: ("dualstack." + $dns), HostedZoneId: $zone, EvaluateTargetHealth: true}}
        + (if $sid != "" then {SetIdentifier: $sid, Weight: ($weight | tonumber)} else {} end)
      )
    }'
}

# Reads change objects on stdin and sends them to Route 53 as one batch.
submit() {
  local batch
  batch=$(jq -s '{Changes: .}')
  aws route53 change-resource-record-sets --hosted-zone-id "${ZONE_ID}" --change-batch "${batch}" >/dev/null
}

command="${1:-}"
case "${command}" in
  init)
    region="${2:?usage: route53.sh init <region>}"
    alias_info=$(alb_alias "${region}")
    read -r dns zone <<<"${alias_info}"
    {
      alias_change UPSERT "${RECORD}" "${region}-region" 100 "${dns}" "${zone}"
      alias_change UPSERT "blue.${RECORD}" "" "" "${dns}" "${zone}"
      alias_change UPSERT "green.${RECORD}" "" "" "${dns}" "${zone}"
    } | submit
    echo "Route 53: ${region} now receives 100% of ${RECORD}"
    ;;

  split)
    r1="${2:?usage: route53.sh split <region1> <region2> <weight1> <weight2>}"
    r2="${3:?}"
    w1="${4:?}"
    w2="${5:?}"
    alias_info1=$(alb_alias "${r1}")
    alias_info2=$(alb_alias "${r2}")
    read -r dns1 zone1 <<<"${alias_info1}"
    read -r dns2 zone2 <<<"${alias_info2}"
    {
      alias_change UPSERT "${RECORD}" "${r1}-region" "${w1}" "${dns1}" "${zone1}"
      alias_change UPSERT "${RECORD}" "${r2}-region" "${w2}" "${dns2}" "${zone2}"
      alias_change UPSERT "${r1}.${RECORD}" "" "" "${dns1}" "${zone1}"
      alias_change UPSERT "${r2}.${RECORD}" "" "" "${dns2}" "${zone2}"
    } | submit
    echo "Route 53: ${r1}=${w1} ${r2}=${w2}"
    ;;

  retire)
    old="${2:?usage: route53.sh retire <old-region> <live-region>}"
    live="${3:?}"
    alias_info=$(alb_alias "${live}")
    read -r dns zone <<<"${alias_info}"

    # A DELETE has to repeat the existing record exactly, so read it back first.
    existing=$(aws route53 list-resource-record-sets --hosted-zone-id "${ZONE_ID}" \
      --query "ResourceRecordSets[?Name=='${RECORD}.' && SetIdentifier=='${old}-region'] | [0]" --output json)

    {
      if [ "${existing}" != "null" ] && [ -n "${existing}" ]; then
        jq -n --argjson record "${existing}" '{Action: "DELETE", ResourceRecordSet: $record}'
      fi
      alias_change UPSERT "${old}.${RECORD}" "" "" "${dns}" "${zone}"
    } | submit
    echo "Route 53: removed the ${old} weighted record, ${old}.${RECORD} now points at ${live}"
    ;;

  *)
    echo "Usage: route53.sh init <region> | split <r1> <r2> <w1> <w2> | retire <old> <live>" >&2
    exit 1
    ;;
esac