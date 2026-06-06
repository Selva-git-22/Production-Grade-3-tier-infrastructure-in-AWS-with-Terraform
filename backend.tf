terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-prod-26-05"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}