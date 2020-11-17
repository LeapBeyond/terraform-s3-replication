# ------------------------------------------------------------------------------
# KMS key for server side encryption on the destination bucket
# ------------------------------------------------------------------------------
resource "aws_kms_key" "destination" {
  provider                = aws.dest
  deletion_window_in_days = 7

  tags = merge(
    {
      "Name" = "destination_data"
    },
    var.tags,
  )
}

resource "aws_kms_alias" "destination" {
  provider      = aws.dest
  name          = "alias/destination"
  target_key_id = aws_kms_key.destination.key_id
}

# ------------------------------------------------------------------------------
# S3 bucket to act as the replication target.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "destination" {
  provider      = aws.dest
  bucket_prefix = var.bucket_prefix
  acl           = "private"
  region        = var.dest_region

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.destination.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = merge(
    {
      "Name" = "Destination Bucket"
    },
    var.tags,
  )
}

