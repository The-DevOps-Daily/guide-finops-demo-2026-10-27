provider "aws" {
  region = var.region

  # Every resource that supports tags gets the cost allocation tags.
  default_tags {
    tags = local.cost_tags
  }
}
