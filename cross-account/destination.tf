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

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.dest_account}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Enable cross account encrypt access for S3 Cross Region Replication",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.source_account}"
      },
      "Action": [
        "kms:Encrypt"
      ],
      "Resource": "*"
    }
  ]
}
POLICY

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

# ------------------------------------------------------------------------------
# The destination bucket needs a policy that allows the source account to
# replicate into it.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "destination" {
  provider = aws.dest
  bucket   = aws_s3_bucket.destination.id

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Id": "",
  "Statement": [
    {
      "Sid": "AllowReplication",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.source_account}:root"
      },
      "Action": [
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ObjectOwnerOverrideToBucketOwner"
      ],
      "Resource": [
        "${aws_s3_bucket.destination.arn}",
        "${aws_s3_bucket.destination.arn}/*"
      ]
    },
    {
      "Sid": "AllowRead",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "s3:List*",
        "s3:Get*"
      ],
      "Resource": [
        "${aws_s3_bucket.destination.arn}",
        "${aws_s3_bucket.destination.arn}/*"
      ]
    }
  ]
}
POLICY

}

