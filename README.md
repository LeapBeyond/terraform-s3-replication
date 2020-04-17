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

### Manual configuration

There is a known deficiency in the AWS API when configuring S3 replication when SSE is in place: there is no way to specify the KMS key that is being used on the destination. This means that there is no way to do this through Terraform either. After applying the Terraform assets, you will need to manually update the source bucket configuration through the AWS Console:

 - Choose the S3 service;
 - Select the source bucket, and then select the `Management` tab;
 - Use the `Replication` section, then edit the single replication rule;
 - On the first step of the edit wizard, choose the correct KMS key from the pick list titled "Choose one or more keys for decrypting source objects";
 - Select the existing configuration on each of the next steps of the wizard.

## Cross-Account replication
The `cross-account` example needs two different profiles, pointing at different accounts, each with a high level of privilege to use IAM, KMS and S3. To begin with , copy the `terraform.tfvars.template` to `terraform.tfvars` and provide the relevant information.

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
### Manual configuration
As with the `same-account` case, we are caught by the deficiency in the AWS API, and need to do some manual steps on both the source and destination account.

On the *source* account AWS Console:
 - Choose the S3 service;
 - Select the source bucket;
 - Select `Management` then `Replication`
 - Choose the source encryption key (this should be easy to find since we gave it an alias);
 - Enable "Change object ownership to destination bucket owner" and provide the *destination* account ID.

 On the *destination* account AWS Console:
  - Choose the S3 service;
  - Select the destination bucket;
  - Select `Management` then `Replication`;
  - From the `Actions` pull down menu choose "Receive objects...";
  - Provide the *source* account ID.

## Notes
There are subtle differences between the cross-account and same-account situations, mainly based around permissions.

To begin with, the destination bucket needs a policy that allows the source account to write to replicate to it. Because we are adding a bucket policy, you will also then need to add additional permissions for users in the destination bucket.

Similarly, the KMS key in the destination account needs to allow access from the source account. By only allowing `kms:Encrypt` action, the access permission does not need to be more complex.

## License
Copyright 2018 Leap Beyond Analytics

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
