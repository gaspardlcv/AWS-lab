# Network Outputs

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.myvpc.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.myvpc.cidr_block
}

output "public_subnet1_id" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_sub1.id
}

output "public_subnet2_id" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_sub2.id
}

output "private_sub1_id" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private_sub1.id
}

output "private_sub2_id" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private_sub2.id
}

output "public_subnet_cidr" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public_sub1.cidr_block
}
output "public_subnet2_cidr" {
  description = "List of public subnet2 CIDR blocks"
  value       = aws_subnet.public_sub2.cidr_block
}

output "private_sub1_cidr" {
  description = "List of private subnet1 CIDR blocks"
  value       = aws_subnet.private_sub1.cidr_block
}
output "private_sub2_cidr" {
  description = "List of private subnet2 CIDR blocks"
  value       = aws_subnet.private_sub2.cidr_block
}

output "nat_gateway1_id" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.nat_gtw1.id
}
output "nat_gateway2_id" {
  description = "List of NAT Gateway2 IDs"
  value       = aws_nat_gateway.nat_gtw2.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.igw.id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = data.aws_availability_zones.available.names
}