#!/usr/bin/env bash
# Usage: empty_bucket.sh <bucket>
set -euo pipefail

bucket="$1"
echo "⚠  Emptying s3://$bucket …"
aws s3 rm "s3://$bucket" --recursive
echo "Bucket emptied."
