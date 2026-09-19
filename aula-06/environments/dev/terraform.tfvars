# environments/dev/terraform.tfvars

project_name = "technova"
environment  = "dev"
vpc_cidr     = "10.0.0.0/16"

subnets = {
  "public-1"  = { cidr = "10.0.1.0/24", az = "us-east-1a", type = "public" }
  "public-2"  = { cidr = "10.0.2.0/24", az = "us-east-1b", type = "public" }
  "private-1" = { cidr = "10.0.3.0/24", az = "us-east-1a", type = "private" }
  "private-2" = { cidr = "10.0.4.0/24", az = "us-east-1b", type = "private" }
}

db_name     = "technova_dev"
db_username = "technova_admin"
db_password = "TechNovaDev2026"
key_name    = "technova-key"