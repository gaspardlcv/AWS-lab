#!/bin/bash

echo "🧪 Testing Network Configuration..."
echo ""

# Get VPC ID
VPC_ID=$(terraform output -raw vpc_id)
echo "✅ VPC ID: $VPC_ID"

# Get Subnets
echo ""
echo "📊 Public Subnets:"
terraform output -json public_subnet_ids | jq -r '.[]'

echo ""
echo "📊 Private Subnets:"
terraform output -json private_subnet_ids | jq -r '.[]'

# Test Internet Gateway
echo ""
echo "🌐 Internet Gateway:"
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[0].InternetGatewayId' \
  --output text

# Test NAT Gateways
echo ""
echo "🔀 NAT Gateways:"
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' \
  --output table

# Test Route Tables
echo ""
echo "🗺️  Route Tables:"
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

echo ""
echo "✅ Network configuration test complete!"