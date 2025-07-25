#!/usr/bin/env bash
# Usage: empty_bucket.sh <bucket>
set -euo pipefail

bucket="$1"
echo "Emptying s3://$bucket …"

# 1) Delete all object versions (for versioned buckets)
echo "Deleting all object versions…"
aws s3api list-object-versions \
  --bucket "$bucket" \
  --query 'Versions[].{Key:Key,VersionId:VersionId}' \
  --output text \
| while read -r key version; do
    if [ -n "$version" ]; then
      aws s3api delete-object \
        --bucket "$bucket" \
        --key "$key" \
        --version-id "$version" \
        >/dev/null
    fi
  done

# 2) Delete all delete-markers
echo "Deleting all delete-markers…"
aws s3api list-object-versions \
  --bucket "$bucket" \
  --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' \
  --output text \
| while read -r key version; do
    if [ -n "$version" ]; then
      aws s3api delete-object \
        --bucket "$bucket" \
        --key "$key" \
        --version-id "$version" \
        >/dev/null
    fi
  done

# 3) Fallback for any remaining objects
echo "Deleting remaining objects (if any)…"
aws s3 rm "s3://$bucket" --recursive

echo "Bucket s3://$bucket is now empty."
