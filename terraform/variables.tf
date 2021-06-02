# Global Variables
variable "region" {
  default = "us-east-2"
}

variable "region_az" {
  type    = list(any)
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

# VPC Related Variables
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_sn_count" {
  default = 2
}

variable "private_sn_count" {
  default = 2
}


# EKS Related Variables
variable "eks_ng_type" {
  default = "t2.micro"
}