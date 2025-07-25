variable "environment" {
  default = "demo123123"
}
variable "aws_region" {
  default = "us-west-2"
}
variable "project_name" {
  default = "short-url"
}
variable "pager_sns_topic_arn" {
  description = "Optional SNS topic ARN for alarm notifications"
  type        = string
  default     = ""
}
