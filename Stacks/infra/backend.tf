###############################################################################
# ROSA HCP Infrastructure - Terraform Backend Configuration
###############################################################################

terraform {
  backend "s3" {
    # These values are configured via:
    # 1. Backend config file: -backend-config=backend.hcl
    # 2. CLI arguments: -backend-config="bucket=my-bucket"
    # 3. Environment variables: TF_VAR_state_bucket, etc.
    #
    # Example backend.hcl:
    # bucket         = "my-terraform-state-bucket"
    # key            = "rosa-hcp/dev/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "terraform-locks"
    # encrypt        = true

    encrypt = true
  }
}

###############################################################################
# Alternative: Local Backend (for development only)
###############################################################################
# Uncomment below and comment out S3 backend for local development
#
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }
