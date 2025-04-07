variable "general_tags" {}

variable "aws_profile" {
  type        = string
  description = "aws profile name on local"
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
  type        = string
  description = "Define VPC CIDR"
}

variable "public_subnet" {
  type        = string
  description = "Define VPC public subnet CIDR block"
}

variable "private_subnet" {
  type        = string
  description = "Define VPC private subnet CIDR block"
}

variable "private_instance_params" {
  type        = any
  description = "Define private ec2 instances parameters for bootstrapping"
  default = {
    instance_count = 0
    instance_type  = "t3.micro"
    ami_id         = "ami-065a492fef70f84b1"
    key_name       = "thanhnc-test"
  }
}

variable "public_instance_params" {
  type        = any
  description = "Define public ec2 instances parameters for bootstrapping"
  default = {
    instance_count = 0
    instance_type  = "t3.micro"
    ami_id         = "ami-065a492fef70f84b1"
    key_name       = "thanhnc-test"
  }
}
