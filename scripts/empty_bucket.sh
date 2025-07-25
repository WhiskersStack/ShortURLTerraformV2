#!/usr/bin/env bash
# empty_bucket.sh  <bucket-name>
set -euo pipefail
bucket="$1"

echo "▸ Emptying s3://$bucket …"

# 0) Suspend versioning so no new delete-markers are created
aws s3api put-bucket-versioning \
  --bucket "$bucket" \
  --versioning-configuration Status=Suspended

# helper – delete one page (≤1000) of items selected by jq filter
delete_page () {
  local jq_filter="$1"
  aws s3api list-object-versions --bucket "$bucket" --output json \
  | jq -c "$jq_filter" \
  | while read -r obj ; do
      key=$(echo "$obj" | jq -r '.Key')
      ver=$(echo "$obj" | jq -r '.VersionId')
      aws s3api delete-object --bucket "$bucket" --key "$key" --version-id "$ver" >/dev/null
    done
}

# 1) Loop until there are *no* versions or delete-markers left
while :; do
  versions=$(aws s3api list-object-versions --bucket "$bucket" \
            --query 'length(Versions || `[]`)'        --output text)
  markers=$(aws s3api list-object-versions --bucket "$bucket" \
            --query 'length(DeleteMarkers || `[]`)'   --output text)

  [[ "$versions" == "0" && "$markers" == "0" ]] && break

  echo "  • Deleting $versions versions and $markers delete-markers…"
  delete_page '.Versions[]?'
  delete_page '.DeleteMarkers[]?'
done


# 2) Final sweep for any plain (un-versioned) objects
aws s3 rm "s3://$bucket" --recursive

echo "Bucket is now empty."
