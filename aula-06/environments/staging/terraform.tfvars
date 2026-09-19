# environments/staging/terraform.tfvars

project_name = "technova"
environment  = "staging"
vpc_cidr     = "10.1.0.0/16"

subnets = {
  "public-1"  = { cidr = "10.1.1.0/24", az = "us-east-1a", type = "public" }
  "public-2"  = { cidr = "10.1.2.0/24", az = "us-east-1b", type = "public" }
  "private-1" = { cidr = "10.1.3.0/24", az = "us-east-1a", type = "private" }
  "private-2" = { cidr = "10.1.4.0/24", az = "us-east-1b", type = "private" }
}

db_name     = "technova_staging"
db_username = "technova_admin"
db_password = "TechNovaStaging2026"
key_name    = "technova-key"