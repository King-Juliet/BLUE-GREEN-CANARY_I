# Cross-Region Blue/Green Canary Deployment

Blue/green deployment with automated canary traffic shifting, across two live AWS regions (`us-east-1` = blue, `eu-north-1` = green), controlled by GitHub Actions + Route 53 weighted DNS. The ecommerce app is just the payload; the deployment pattern is the point.

**Prerequisites:** an AWS account with IAM admin rights, Terraform `>= 1.10.5` (earlier versions don't support the S3 backend locking this project uses), AWS CLI v2, Docker, and `jq`.

## Fork & set up

1. **Fork this repo**, then clone your fork.
2. **Create your own Terraform state bucket** (S3 names are globally unique, so you can't reuse the original):
```bash
   aws s3api create-bucket --bucket <your-bucket> --region us-east-1
```
   Update the `bucket` value in `infrastructure/us-east-1/backend.tf` , `infrastructure/eu-north-1/backend.tf` and `infrastructure/us-east-1/backend.tf`.
3. **Set up OIDC** so GitHub authenticates to AWS with no stored keys: create an OIDC provider (`token.actions.githubusercontent.com`, audience `sts.amazonaws.com`), then a role trusting it, scoped to `repo:<you>/<repo>:*`. **Gotcha:** repos created after July 2026 get an immutable `owner@id/repo@id` subject claim — if auth fails, check CloudTrail's `AssumeRoleWithWebIdentity` event for the real value and match it exactly. Attach necessary permissions to the policy attached to the OIDC.
4. **Set repo variables** (Settings → Secrets and variables → Actions → Variables, and under the `production` Environment): `AWS_ROLE_ARN`, `TF_STATE_BUCKET`, `ROUTE53_ZONE_NAME` (e.g. `bluegreen-canary.test`), `ROUTE53_RECORD_NAME` (e.g. `app.bluegreen-canary.test`), `BLUE_REPOSITORY_URI`/`GREEN_REPOSITORY_URI`, `BLUE_ALB_NAME`/`GREEN_ALB_NAME`, `BLUE_ALARM_NAME`/`GREEN_ALARM_NAME`. 
The last six follow Terraform's own naming pattern (${project}-${environment}-..., from infrastructure/*/locals.tf) — with this repo's default project/environment values, they resolve to:

BLUE_REPOSITORY_URI → <account-id>.dkr.ecr.us-east-1.amazonaws.com/bluegreen-canary-blue
GREEN_REPOSITORY_URI → <account-id>.dkr.ecr.eu-north-1.amazonaws.com/bluegreen-canary-green
BLUE_ALB_NAME → bluegreen-canary-blue-blue-alb
GREEN_ALB_NAME → bluegreen-canary-green-green-alb
BLUE_ALARM_NAME → bluegreen-canary-blue-blue-alb-5xx
GREEN_ALARM_NAME → bluegreen-canary-green-green-alb-5xx

## Run it

Push to `main`. CI validates the code and Terraform; CD then provisions both regions and deploys both — the first run always leaves 100% of traffic on blue. Watch it under the **Actions** tab.

Then, once per region, initialize the database — the schema isn't applied automatically:
```bash
psql "host=<rds-endpoint> dbname=appdb user=appuser sslmode=disable" -f applications/backend/schema.sql
```

## Verify the canary

Every push *after* the first is a canary run: 10% of traffic shifts to the idle region, holds for ~5 minutes while a CloudWatch alarm is watched, then promotes to 100% or rolls back automatically. Watch it with this — the exact command used to verify it, run at three points:

```bash
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "bluegreen-canary.test." --query 'HostedZones[0].Id' --output text)
aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" \
  --query "ResourceRecordSets[?Name=='app.bluegreen-canary.test.']"
```

| When | What you'll see |
|---|---|
| Initial deployment, before any canary | blue `Weight: 100`, green `Weight: 0` |
| Mid-canary, right after pushing a change | blue `Weight: 90`, green `Weight: 10` |
| After the bake window completes clean | blue `Weight: 0`, green `Weight: 100` |

This bypasses public DNS entirely — `.test` is IANA-reserved and never publicly resolvable — so it works from anywhere with AWS CLI access, no domain setup needed.

## Cost & cleanup

Two regions, two RDS instances, up to 8 VPC endpoints, two ALBs — real, billable resources. Destroy when done:
```bash
terraform -chdir=infrastructure/global destroy -auto-approve
terraform -chdir=infrastructure/us-east-1 destroy -auto-approve
terraform -chdir=infrastructure/eu-north-1 destroy -auto-approve
```

## Known gaps

- Database schema must be applied manually (above) — not yet part of the pipeline.
- GitHub variables mirroring Terraform-generated names aren't auto-synced — a Terraform rename needs a manual update here too.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | Check CloudTrail's `AssumeRoleWithWebIdentity` event for the real `sub` claim, match the trust policy to it |
| Backend `db: "not-ready"` (hangs) | Missing VPC interface endpoint for `com.amazonaws.<region>.ssm` |
| Backend `db: "down"` | RDS defaults to requiring SSL on Postgres 15+; add a parameter group with `rds.force_ssl = 0`, reboot if the DB already existed |
| `RepositoryNotEmptyException` on destroy | Add `force_delete = true` to the ECR repository resource |
| `tag invalid ... immutable` on push | Push a new commit instead of re-running a failed job — reruns reuse the same image tag |
