###############################################################################
# 1. Render the HTML template, wiring in the live Lambda Function URL
###############################################################################
data "template_file" "site_html" {
  template = file("${path.module}/S3/website/WhiskersURL.tpl.html")

  vars = {
    lambda_url = module.lambda.function_url # <-- comes from your lambda module
  }
}

###############################################################################
# 2. Push the rendered HTML to the private bucket that the CF stack created
###############################################################################
resource "aws_s3_object" "site_index" {
  bucket       = module.static_site.bucket_name # output we exposed earlier
  key          = "WhiskersURL.html"
  content      = data.template_file.site_html.rendered
  content_type = "text/html"

  # Change detection: if the rendered HTML changes, re-upload
  etag = md5(data.template_file.site_html.rendered)

  depends_on = [module.static_site] # ensures the bucket exists first
}

###############################################################################
# 3. Auto-invalidate CloudFront so the new HTML shows immediately
###############################################################################
resource "null_resource" "cf_invalidation" {
  # re-run whenever the S3 object ETag changes
  triggers = {
    etag = aws_s3_object.site_index.etag
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${module.static_site.cloudfront_distribution_id} --paths /WhiskersURL.html /"
  }


  depends_on = [aws_s3_object.site_index]
}
