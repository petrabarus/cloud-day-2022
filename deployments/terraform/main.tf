terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }


}

provider "aws" {

}

locals {
  name = "cloudday22"
}

resource "aws_kms_key" "encryption_key" {
  description             = "KMS key 1 in ${local.name}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "encryption_key" {
  name          = "alias/${local.name}-enc-key"
  target_key_id = aws_kms_key.encryption_key.key_id
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

