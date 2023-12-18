variable "region" {
  default = "eu-central-1"
  type = string
  description = "The region you want to deploy the infrastructure in"
}

variable "hosted_zone_id" {
  type = string
  description = ""
}
