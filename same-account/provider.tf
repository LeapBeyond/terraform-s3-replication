provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "source"
  region  = var.source_region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "dest"
  region  = var.dest_region
  profile = var.aws_profile
}

