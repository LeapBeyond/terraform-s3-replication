# ------------------------------------------------------------------------------
# IAM role that S3 can use to read our bucket for replication
# ------------------------------------------------------------------------------
resource "aws_iam_role" "replication" {
  name_prefix = "replication"
  description = "Allow S3 to assume the role for replication"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "s3-replication-assume",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  name_prefix = "replication"
  description = "Allows reading for replication."

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.source.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.source.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.destination.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "replication" {
  name       = "replication"
  roles      = ["${aws_iam_role.replication.name}"]
  policy_arn = "${aws_iam_policy.replication.arn}"
}

# ------------------------------------------------------------------------------
# Key for server side encryption on the source bucket
# ------------------------------------------------------------------------------
resource "aws_kms_key" "source" {
  deletion_window_in_days = 7

  tags = "${merge(map("Name", "source_data"), var.tags)}"
}

resource "aws_kms_alias" "source" {
  name          = "alias/source"
  target_key_id = "${aws_kms_key.source.key_id}"
}

# ------------------------------------------------------------------------------
# S3 bucket to act as the replication source, i.e. the primary copy of the data
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "source" {
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
        kms_master_key_id = "${aws_kms_key.source.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  replication_configuration {
    role = "${aws_iam_role.replication.arn}"

    rules {
      prefix = ""
      status = "Enabled"

      destination {
        bucket = "${aws_s3_bucket.destination.arn}"
      }
    }
  }

  tags = "${merge(map("Name", "Source Bucket"), var.tags)}"
}
