#!/usr/bin/env bash
# Usage: deploy_assets.sh <bucket> <distribution-id> <file1> [file2 …]
set -euo pipefail

bucket="$1"; dist="$2"; shift 2
assets=("$@")

printf "↗  Uploading %s to s3://%s\n" "${assets[@]}" "$bucket"
for f in "${assets[@]}"; do
  aws s3 cp "$f" "s3://$bucket/$(basename "$f")"
done

printf "🚀  Invalidating CloudFront cache…\n"
aws cloudfront create-invalidation \
  --distribution-id "$dist" \
  --paths $(printf "/%s " "${assets[@]/#/}") "/"

echo "✔  Done."
