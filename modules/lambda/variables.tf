variable "lambda_function_name" {
  description = "Logical name for the Lambda function"
  type        = string
  default     = "short-url-handler"
}

variable "handler_file" {
  description = "Absolute or relative path to the Python source that defines lambda_handler"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Existing DynamoDB table that stores long ↔ short mappings"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.12"
}

variable "cors_allow_origins" {
  description = "List of allowed origins for the Function URL CORS config"
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default     = {}
}
variable "existing_role_name" {
  description = "Name of an existing IAM role to use for Lambda execution"
  type        = string
  default     = "LabRole"  # Default name for the pre-created role
}