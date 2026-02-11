variable "cidr" {
  default = "10.0.0.0/16"
}

variable "myip" {
  description = "your public ip for the ssh access"
  default     = "public-ip/32"
}
variable "region" {
  default = "us-east-1"
}
variable "az1" {
  default = "us-east-1a"
}
variable "az2" {
  default = "us-east-1b"
}
variable "publiccidr1" {
  default = "10.0.0.0/24"
}
variable "publiccidr2" {
  default = "10.0.1.0/24"
}
variable "privatecidr1" {
  default = "10.0.10.0/24"
}
variable "privatecidr2" {
  default = "10.0.11.0/24"
}
variable "kubernetes_subnet_cidr" {
    description = "CIDR block for the Kubernetes subnets"
    default     = "10.0.10.0/24"
  
}