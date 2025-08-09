variable "instance_name" {}
variable "subnet_ids" { type = list(string) }
variable "min_size" { default = 1 }
variable "max_size" { default = 3 }
variable "desired_capacity" { default = 1 }
variable "alb_name" {}
variable "alb_security_groups" { type = list(string) }
