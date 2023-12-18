terraform {
  backend "s3" {
    bucket = "terraform-log-bucket"
    region = "eu-central-1"
    key = "terraform.tfstate"
  }
}
