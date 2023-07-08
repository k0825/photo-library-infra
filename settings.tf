terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.2"
    }
  }

  backend "s3" {
    bucket = "ikari-tfstate"
    key    = "photo-library-infra/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
