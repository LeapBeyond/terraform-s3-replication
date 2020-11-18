output "destination_bucket" {
  value = aws_s3_bucket.destination.arn
}

output "source_bucket" {
  value = aws_s3_bucket.source.arn
}

