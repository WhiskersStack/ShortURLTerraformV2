variable "table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "WhiskersURL"
}

variable "enable_ttl" {
  description = "Turn on TTL using attribute 'expires'"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the table"
  type        = map(string)
  default     = {}
}
