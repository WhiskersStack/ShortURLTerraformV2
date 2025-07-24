variable "stack_name" {
  description = "CloudFormation stack name"
  type        = string
}

variable "template_path" {
  description = "Path to the deploy_s3.yaml CloudFormation template"
  type        = string
}

variable "bucket_name" {
  description = "Globally-unique S3 bucket name for the static site"
  type        = string
}

variable "site_index" {
  description = "Root HTML document served by the bucket"
  type        = string
  default     = "WhiskersURL.html"
}

variable "tags" {
  description = "Tags applied to the CloudFormation stack"
  type        = map(string)
  default     = {}
}
