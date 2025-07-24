aws cloudformation deploy \
  --template-file deploy_s3.yaml \
  --stack-name short-url-site-v2 \
  --parameter-overrides BucketName=whiskers-url-site \
  --capabilities CAPABILITY_NAMED_IAM



aws cloudformation describe-stacks \
  --stack-name short-url-site-v2 \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontURL'].OutputValue" \
  --output text


aws s3 sync S3/website/ s3://whiskers-url-site-dev