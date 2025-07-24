output "function_url" {
  description = "Public URL of the Lambda function"
  value       = aws_lambda_function_url.this.function_url
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.this.arn
}
