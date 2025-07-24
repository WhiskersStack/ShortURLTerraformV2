resource "aws_cloudformation_stack" "this" {
  name          = var.stack_name
  template_body = file(var.template_path)

  parameters = {
    BucketName = var.bucket_name
    SiteIndex  = var.site_index
  }

  # the CF template creates a named bucket policy → needs this capability
  capabilities = ["CAPABILITY_NAMED_IAM"]

  tags = var.tags
}

# propagate interesting outputs to callers
output "cloudfront_domain" {
  description = "Public CloudFront URL (e.g. dxxxxx.cloudfront.net)"
  value       = aws_cloudformation_stack.this.outputs["CloudFrontURL"]
}

output "bucket_name" {
  description = "Name of the private S3 bucket that stores the site"
  value       = var.bucket_name
}
