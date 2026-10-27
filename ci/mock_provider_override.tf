# Copied into infra/ by scripts/lib.sh in CI only. Mock credentials let
# `terraform plan` run without an AWS account: no resource exists yet and the
# configuration reads nothing from AWS, so the plan needs no API calls.
provider "aws" {
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}
