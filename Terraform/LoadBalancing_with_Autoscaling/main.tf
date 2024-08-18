resource "aws_vpc" "nv_vpc" {
  cidr_block = "${var.vpc_cidr}"
  tags = {
	Name = "nv_vpc"
}
}

resource "aws_internet_gateway" "nv_igw" {
  vpc_id = aws_vpc.nv_vpc.id

  tags = {
    Name = "nv_igw"
}
}

resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.nv_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nv_igw.id
  }

  tags = {
    Name = "pub_rt"
}
}

resource "aws_subnet" "pub_sub1" {
  vpc_id     = aws_vpc.nv_vpc.id
  cidr_block = "${var.pubsub1_cidr}"
  availability_zone = "${var.pubsub1_az}"
  map_public_ip_on_launch = true
  tags = {
    Name = "pub_sub1"
}
}

resource "aws_subnet" "pub_sub2" {
  vpc_id     = aws_vpc.nv_vpc.id
  cidr_block = "${var.pubsub2_cidr}"
  availability_zone = "${var.pubsub2_az}"
  map_public_ip_on_launch = true
  tags = {
    Name = "pub_sub2"
}
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.pub_sub1.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.pub_sub2.id
  route_table_id = aws_route_table.pub_rt.id
}


resource "aws_security_group" "nv_sg" {
  name = "nv_vpc_sg"
  vpc_id = aws_vpc.nv_vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows SSH from anywhere; replace with specific IP if needed
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows HTTP from anywhere
 }

 egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"           # -1 allows all protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allows all outbound traffic
  }

  tags = {
    Name = "nv_sg"
  }
}

/* resource "aws_instance" "server-1" {
  ami           = "${var.ami_id}"
  instance_type = "${var.server_type}"
  subnet_id = aws_subnet.pub_sub1.id
  user_data = file("/home/ubuntu/MyProjects/Terraform/Vpc_Peering/s1_script.sh")
  security_groups = [aws_security_group.nv_sg.id]
  key_name = "${var.pubkey_name}"
  associate_public_ip_address = "true"

  tags = {
    Name = "server-1"
  }
}

resource "aws_instance" "server-2" {
  ami           = "${var.ami_id}"
  instance_type = "${var.server_type}"
  subnet_id = aws_subnet.pub_sub2.id
  user_data = file("/home/ubuntu/MyProjects/Terraform/Vpc_Peering/s2_script.sh")
  security_groups = [aws_security_group.nv_sg.id]
  associate_public_ip_address = "true"

  tags = {
    Name = "server-2"
} 
}  */

resource "aws_lb" "nv_alb" {

  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nv_sg.id]
  subnets            = [aws_subnet.pub_sub1.id, aws_subnet.pub_sub2.id]

  tags = {
    Name = "my-alb"
  }
}


resource "aws_lb_target_group" "nv-tg" {

  name     = "nv-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.nv_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
}


resource "aws_lb_listener" "nv_listener" {

  load_balancer_arn = aws_lb.nv_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nv-tg.arn
  }
}

/*
resource "aws_lb_target_group_attachment" "attachment-1" {
  target_group_arn = aws_lb_target_group.nv_tg.arn
  target_id        = aws_instance.server-1.id
  port             = 80
}


resource "aws_lb_target_group_attachment" "attachment-2" {
  target_group_arn = aws_lb_target_group.nv_tg.arn
  target_id        = aws_instance.server-2.id
  port            = 80
}
*/



resource "aws_launch_template" "nv_lt" {

  name          = "nv_lt"
  image_id      = "${var.ami_id}"
  instance_type = "${var.server_type}"
  key_name = "${var.pubkey_name}"
  vpc_security_group_ids = [aws_security_group.nv_sg.id]
  user_data = filebase64("/home/ubuntu/MyProjects/Terraform/LoadBalancer_with_Autoscaling/as_script.sh")
  tags = {
    Name = "nv_lt"
  }
}



resource "aws_autoscaling_group" "nv_asg" {

  launch_template {
    id      = aws_launch_template.nv_lt.id
    version = "$Latest"
  }

  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.pub_sub1.id, aws_subnet.pub_sub2.id]
  target_group_arns = [aws_lb_target_group.nv-tg.arn]

}



resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {

  alarm_name          = "scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.nv_asg.name
  }

  alarm_actions = [
    aws_autoscaling_policy.scale_up_policy.arn
  ]
}



resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {

  alarm_name          = "scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.nv_asg.name
  }

  alarm_actions = [
    aws_autoscaling_policy.scale_down_policy.arn
  ]
}




resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.nv_asg.name
}



resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.nv_asg.name
}

