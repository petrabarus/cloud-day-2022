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