terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0" # v5+ definitely has the resource
    }
  }

  required_version = ">= 1.3.0"
}
provider "aws" {
  region = "us-west-2" # or your preferred region
}
module "static_site" {
  source        = "./modules/static_site_cf"
  stack_name    = "short-url-site-${var.environment}"
  bucket_name   = "whiskers-url-site-${var.environment}"
  template_path = "${path.module}/S3/deploy_s3.yaml"
  site_index    = "WhiskersURL.html"

  tags = {
    Project     = "ShortURL"
    Environment = var.environment
  }
}


output "static_site_url" {
  value       = module.static_site.cloudfront_domain
  description = "CloudFront URL of the deployed static site"
}


module "lambda" {
  source = "./modules/lambda"

  handler_file        = "${path.module}/lambda_func/lambda_function.py"
  dynamodb_table_name = "WhiskersURL" #module.dynamodb.table_name
  #cors_allow_origins   = [module.static_site.cloudfront_domain]
}

module "dynamodb" {
  source     = "./modules/dynamoDB"
  table_name = "WhiskersURL" #"WhiskersURL-${var.environment}"
  enable_ttl = true

  tags = {
    Project     = "ShortURL"
    Environment = var.environment
  }
}



#########################
#  Locate asset files
#########################
locals {
  asset_files = [
    "${path.module}/S3/website/whiskersstack-logo.png",
    # add more files here
  ]
}

##############################################
#  Upload assets + invalidate CloudFront
##############################################
resource "null_resource" "upload_assets" {
  # Run again only when a file’s checksum changes
  triggers = {
    etag = join(",", [for f in local.asset_files : filesha256(f)])
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${path.module}/scripts/deploy_assets.sh \
        ${module.static_site.bucket_name} \
        ${module.static_site.cloudfront_distribution_id} \
        ${join(" ", local.asset_files)}
    EOT
  }

  depends_on = [
    module.static_site,      # bucket must exist
    aws_s3_object.site_index # HTML already uploaded
  ]
}

##############################################
#  Empty bucket just before destroy
##############################################
resource "null_resource" "clean_bucket" {
  # Triggers are stored in the resource state,
  # so they're still available during destroy.
  triggers = {
    bucket = module.static_site.bucket_name
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/empty_bucket.sh ${self.triggers.bucket}"
  }

  # Make sure the bucket exists first
  depends_on = [module.static_site]
}
