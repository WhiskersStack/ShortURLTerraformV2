output "lambda_function_name" {
  value = module.lambda.function_name
}
output "cf_distribution_id" {
  value = module.static_site.cloudfront_distribution_id
}
