# ------------------------------------------------------------------------------
# KMS key for server side encryption on the destination bucket
# ------------------------------------------------------------------------------
resource "aws_kms_key" "destination" {
  deletion_window_in_days = 7

  tags = "${merge(map("Name", "destination_data"), var.tags)}"
}

resource "aws_kms_alias" "destination" {
  name          = "alias/destination"
  target_key_id = "${aws_kms_key.destination.key_id}"
}

# ------------------------------------------------------------------------------
# S3 bucket to act as the replication target.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "destination" {
  bucket_prefix = "${var.bucket_prefix}"
  acl           = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.destination.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = "${merge(map("Name", "Destination Bucket"), var.tags)}"
}
