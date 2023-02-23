variable "vpc_id" {
  description = "The id for the VPC to use"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "The IDs for the private subnets"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "The IDs for the public subnets"
  type        = list(string)
  default     = []
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = ""
}
