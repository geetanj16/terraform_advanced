variable "vpc_name" {
    description = "Enter the name of VPC"
    type        = string
    default     = "My_VPC"
}

variable "vpc_cidr_block" {
    description = "Enter the CIDR of VPC"
    type        = string
    default     = "10.0.0.0/16"
}

