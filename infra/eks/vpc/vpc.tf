data "aws_availability_zones" "available" {
}

# VPC
resource "aws_vpc" "this" {
  cidr_block = var.cidr

  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags = merge(
    local.common_tags,
    {
      Name = var.vpc_name
    },
  )
}

#Internet Gatway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "Internet-Gateway"
    },
  )
}