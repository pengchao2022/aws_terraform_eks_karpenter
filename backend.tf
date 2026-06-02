terraform {
  # All specific Buckets, Keys, and Regions are dynamically injected by GitHub Actions during init
  backend "s3" {}
}