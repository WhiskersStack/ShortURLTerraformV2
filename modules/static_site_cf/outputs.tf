# output "static_site_url" {
#   value       = aws_cloudformation_stack.this.outputs["CloudFrontURL"]
#   description = "Public CloudFront URL (e.g. dxxxxx.cloudfront.net)"
# }
output "cloudfront_distribution_id" {
  value       = aws_cloudformation_stack.this.outputs["DistributionId"]
  description = "ID of the CloudFront distribution"
}
