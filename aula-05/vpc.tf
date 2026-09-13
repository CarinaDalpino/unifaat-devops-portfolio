# -----------------------------------------------------------------------------
# DATA SOURCE — AZs disponíveis na região
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
    Aula        = "05"
  }
}

# -----------------------------------------------------------------------------
# INTERNET GATEWAY
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
    Aula        = "05"
  }
}

# -----------------------------------------------------------------------------
# SUBNET PÚBLICA — EC2 (AZ 1)
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
    Type        = "public"
    Aula        = "05"
  }
}

# -----------------------------------------------------------------------------
# SUBNETS PRIVADAS — RDS (2 AZs diferentes — obrigatório para DB Subnet Group)
# -----------------------------------------------------------------------------
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "${var.project_name}-private-subnet-1"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
    Type        = "private"
    Aula        = "05"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1] # AZ diferente!

  tags = {
    Name        = "${var.project_name}-private-subnet-2"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
    Type        = "private"
    Aula        = "05"
  }
}

# -----------------------------------------------------------------------------
# ROUTE TABLE PÚBLICA + ASSOCIAÇÃO
# -----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
    Aula        = "05"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
