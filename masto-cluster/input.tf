variable "vpc_id" {
  description = "The id for the VPC to use"
  type        = string
  default     = ""
}

variable "private_subnet_id" {
  description = "The ID for the private subnet"
  type        = string
  default     = ""
}

variable "public_subnet_id" {
  description = "The ID for the public subnet"
  type        = string
  default     = ""
}
