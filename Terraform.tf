# Define the provider
provider "aws" {
  region = "us-east-1"
}

# Define the EC2 instance
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "web-server"
  }
}

# Define the RDS database
resource "aws_db_instance" "db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
}

# Define the Load Balancer
resource "aws_elb" "web" {
  name               = "web-lb"
  availability_zones = ["us-east-1a", "us-east-1b"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
}

# Define the security group for the EC2 instance
resource "aws_security_group" "web" {
  name_prefix = "web-"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Attach security group to EC2 instance
resource "aws_security_group_attachment" "web" {
  security_group_id = aws_security_group.web.id
  instance_id       = aws_instance.web.id
}

# Attach EC2 instance to Load Balancer
resource "aws_elb_attachment" "web" {
  elb        = aws_elb.web.id
  instance   = aws_instance.web.id
  stickiness = true
}
