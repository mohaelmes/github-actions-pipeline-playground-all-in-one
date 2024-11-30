output "website_bucket_name" {
  description = "Name of the S3 bucket hosting the website"
  value       = aws_s3_bucket.website.id
}

output "website_url" {
  description = "URL of the website"
  value       = "http://${aws_s3_bucket.website.bucket}.s3-website-${var.aws_region}.amazonaws.com"
}

output "artifacts_bucket_name" {
  description = "Name of the S3 bucket storing artifacts"
  value       = aws_s3_bucket.artifacts.id
}
