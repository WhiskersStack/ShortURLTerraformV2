###############################################################################
# CloudWatch Monitoring & Alarms for URL-shortener stack
###############################################################################

locals {
  # If you provided an SNS topic ARN, put it into a list, otherwise leave empty
  alarm_actions = var.pager_sns_topic_arn != "" ? [var.pager_sns_topic_arn] : []
}


###################################
# 1. Alarm: Lambda Errors
###################################
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-LambdaErrors"
  alarm_description   = "Alarm on any Lambda invocation error"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"

  dimensions = {
    FunctionName = module.lambda.function_name
  }

  threshold     = 1
  alarm_actions = local.alarm_actions
}

###################################
# 2. Alarm: CloudFront 5xx errors
###################################
resource "aws_cloudwatch_metric_alarm" "cf_5xx" {
  alarm_name          = "${var.project_name}-CF5xxErrorRate"
  alarm_description   = "Alarm when CloudFront 5xx error rate is ≥1% over 5m"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"

  dimensions = {
    DistributionId = module.static_site.cloudfront_distribution_id
    Region         = "Global"
  }

  threshold     = 1
  alarm_actions = local.alarm_actions
}

###################################
# 3. Dashboard: summary view
###################################
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", module.lambda.function_name, { "stat" : "p95" }],
            [".", "Errors", ".", ".", { "yAxis" : "right" }]
          ]
          view   = "timeSeries"
          title  = "Lambda p95 Duration & Errors"
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", module.static_site.cloudfront_distribution_id, "Region", "Global"],
            [".", "5xxErrorRate", ".", ".", "Region", "Global", { "yAxis" : "right" }]
          ]
          view   = "timeSeries"
          title  = "CloudFront Traffic & 5xx Error Rate"
          region = var.aws_region
        }
      }
    ]
  })
}
