provider "aws" {
  region  = "eu-south-1"
  profile = "perk"
}

terraform {
  backend "local" {
    path = "./.terraform/terraform.state"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
