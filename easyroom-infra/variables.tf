variable "aws_region" {
  description = "The AWS region to deploy resources."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "easyroom"
}

variable "instance_type" {
  description = "EC2 instance type for all servers."
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "frontend_ebs_size" {
  description = "EBS volume size for Frontend EC2 in GB."
  type        = number
  default     = 20
}

variable "backend_ebs_size" {
  description = "EBS volume size for Backend EC2 in GB."
  type        = number
  default     = 20
}

variable "database_ebs_size" {
  description = "EBS volume size for Database EC2 in GB."
  type        = number
  default     = 60
}

variable "my_ip" {
  description = "Your public IP address for SSH access. Use 0.0.0.0/0 for anywhere (less secure)."
  type        = string
  default     = "0.0.0.0/0" # Consider changing this to your actual IP for better security
}

variable "db_user" {
  description = "Database master username."
  type        = string
  default     = "easyroomadmin"
}

variable "db_password" {
  description = "Database master password."
  type        = string
  sensitive   = true
  default     = "EasyRoomPass123!" # CHANGE THIS IN PRODUCTION
}

