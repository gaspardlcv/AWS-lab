resource "aws_vpc" "myvpc" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "wiz-vpc"
  }
}
resource "aws_subnet" "public_sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.publiccidr1
  availability_zone       = var.az1
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.publiccidr2
  availability_zone       = var.az2
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}
resource "aws_subnet" "private_sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.privatecidr1
  availability_zone       = var.az1
  map_public_ip_on_launch = true

  tags = {
    Name = "lab-public-subnet-1"
  }
}

resource "aws_subnet" "private_sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.privatecidr2
  availability_zone       = var.az2
  map_public_ip_on_launch = true

  tags = {
    Name = "lab-public-subnet-2"
  }
}

// Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "lab-igw"
  }
}

// NAT Gateway + EIP for NAT

resource "aws_eip" "nat1" {
  domain = "vpc"

  tags = {
    Name = "lab-nat-eip1"
  }

  depends_on = [aws_internet_gateway.myvpc]
}
resource "aws_eip" "nat2" {
  domain = "vpc"

  tags = {
    Name = "lab-nat-eip2"
  }

  depends_on = [aws_internet_gateway.myvpc]
}

resource "aws_nat_gateway" "nat_gtw1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public_sub1.id

  tags = {
    Name = "lab-naz-gw-1"
  }

  depends_on = [aws_internet_gateway.myvpc]
}
resource "aws_nat_gateway" "nat_gtw2" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.public_sub2.id

  tags = {
    Name = "lab-naz-gw-2"
  }

  depends_on = [aws_internet_gateway.myvpc]
}

// Route Tables

resource "aws_route_table" "public_rt1" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "lab-public-rt1"
  }
}
resource "aws_route_table" "public_rt2" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "lab-public-r2"
  }
}
resource "aws_route_table" "private_rt1" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "lab-private-rt1"
  }
}
resource "aws_route_table" "private_rt2" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "lab-private-rt2"
  }
}

// Route Rules

resource "aws_route" "externalroute1" {
  route_table_id         = aws_route_table.public_rt1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "internalroute1" {
  route_table_id         = aws_route_table.private_rt1.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_nat_gateway.nat_gtw1.id

}

resource "aws_route" "externalroute2" {
  route_table_id         = aws_route_table.public_rt2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "internalroute2" {
  route_table_id         = aws_route_table.private_rt2.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_nat_gateway.nat_gtw2.id

}

// Route Table Association

resource "aws_route_table_association" "public_rt1" {
  subnet_id      = aws_subnet.public_sub1.id
  route_table_id = aws_route_table.public_rt1.id
}

resource "aws_route_table_association" "public_rt2" {
  subnet_id      = aws_subnet.public_sub2.id
  route_table_id = aws_route_table.public_rt2.id
}
resource "aws_route_table_association" "private_rt1" {
  subnet_id      = aws_subnet.private_sub1.id
  route_table_id = aws_route_table.private_rt1.id
}
resource "aws_route_table_association" "private_rt2" {
  subnet_id      = aws_subnet.private_sub2.id
  route_table_id = aws_route_table.private_rt2.id
}
