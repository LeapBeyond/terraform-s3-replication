# S3 Replication with Terraform

The two sub-directories here illustrate configuring S3 bucket replication where server side encryption is in place. The various how-to and walkthroughs around S3 bucket replication don't touch the case where server side encryption is in place, and there are some annnoyances around it.

These examples assume that you have command-line profiles with a high level of privilege to use IAM, KMS and S3. For the `cross-account` example, these will need to be profiles accessing two different accounts.

## Same-Account replication
The `same-account` example needs a single profile with a high level of privilege to use IAM, KMS and S3. To begin with, copy the `terraform.tfvars.template` to `terraform.tfvars` and provide the relevant information.

Subsequent to that, do:

```
terraform init
terraform apply
```

At the end of this, the two buckets should be reported to you:

```
Outputs:
destination_bucket = arn:aws:s3:::crr-example20180910103218029300000002
source_bucket = arn:aws:s3:::crr-example20180910103223585300000003
```

The Terraform scripts drop an object `sample.txt` in the source bucket which should be able to see synchronized to the destination.

### Regions
The `variables.tf` file specifies the regions for the two S3 buckets - you may want to change these.

### Manual configuration

There is a known deficiency in the AWS API when configuring S3 replication when SSE is in place: there is no way to specify the KMS key that is being used on the destination. This means that there is no way to do this through Terraform either. After applying the Terraform assets, you will need to manually update the source bucket configuration through the AWS Console:

 - Choose the S3 service;
 - Select the source bucket, and then select the `Management` tab;
 - Use the `Replication` section, then edit the single replication rule;
 - On the first step of the edit wizard, choose the correct KMS key from the pick list titled "Choose one or more keys for decrypting source objects";
 - Select the existing configuration on each of the next steps of the wizard.
