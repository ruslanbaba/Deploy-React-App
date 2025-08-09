module "ec2_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  name    = var.instance_name
  launch_template_name = var.instance_name
  vpc_zone_identifier  = var.subnet_ids
  min_size = var.min_size
  max_size = var.max_size
  desired_capacity = var.desired_capacity
  health_check_type = "EC2"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  name    = var.alb_name
  subnets = var.subnet_ids
  security_groups = var.alb_security_groups
}
