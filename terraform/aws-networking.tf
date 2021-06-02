### AWS VPC Configurations ###

# VPC Creation
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "k8s-vpc"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Public Subnets Creation
resource "aws_subnet" "k8s_public_subnet" {
  count                   = var.public_sn_count
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = local.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.region_az[count.index]

  tags = {
    Name                     = "k8s_public_${count.index + 1}"
  }
}

resource "aws_route_table" "k8s_public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    "Name" = "k8s_public_rt"
  }
}

resource "aws_route_table_association" "k8s_public_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.k8s_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.k8s_public_rt.id
}


# Public Subnets Creation
resource "aws_subnet" "k8s_private_subnet" {
  count                   = var.private_sn_count
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = local.private_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.region_az[count.index]

  tags = {
    Name                              = "k8s_private_${count.index + 1}"
  }
}

resource "aws_default_route_table" "k8s_private_rt" {
  default_route_table_id = aws_vpc.k8s_vpc.default_route_table_id

  tags = {
    "Name" = "k8s_private_rt"
  }
}


# Routing and Gateway Configurations for Public Subnet
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    "Name" = "k8s_igw"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.k8s_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.k8s_igw.id
}


# Routing and Gateway Configurations for Private Subnet
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "k8s_nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.k8s_public_subnet[0].id

  tags = {
    "Name" = "k8s_nat_gw"
  }
}

resource "aws_route" "default_nat_route" {
  route_table_id         = aws_default_route_table.k8s_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.k8s_nat_gw.id
}