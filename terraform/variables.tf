variable "cidr" {
  default = "10.0.0.0/16"
}

variable "myip" {
  description = "your public ip for the ssh access"
  default = "public-ip/32"
}
