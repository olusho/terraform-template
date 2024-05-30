# Define AWS provider
provider "aws" {
  region = "ca-central-1" # Specify your desired region
}

# Get VPC ID using data block
data "aws_vpc" "my_vpc" {
  tags = {
    Name = "MetroVPC" # Specify the name of your VPC
  }
}

data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.my_vpc.id]
  }
}

data "aws_subnet" "subnet1" {
  filter {
    name   = "tag:Name"
    values = ["Subnet1"]
  }
}

data "aws_subnet" "subnet3" {
  filter {
    name   = "tag:Name"
    values = ["Subnet3"]
  }
}

# Create S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-name9871398138y438642" # Replace with your desired bucket name
}

# Create IAM role
resource "aws_iam_role" "my_role" {
  name = "my-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach sample IAM policy to IAM role
resource "aws_iam_role_policy_attachment" "my_policy_attachment" {
  role       = aws_iam_role.my_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess" # Example policy, replace with your desired policy ARN
}

# Create security group with port 3306 open
resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"
  description = "Allow MySQL traffic"
  vpc_id      = data.aws_vpc.my_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = data.aws_subnets.example.ids
}

# Create RDS instance
resource "aws_db_instance" "my_rds_instance" {
  identifier             = "my-rds-instance"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"         # Choose a supported engine version
  instance_class         = "db.t3.micro" # Choose a supported instance class
  username               = "admin"
  password               = "mysecretpassword"
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
}

# Create Glue job
resource "aws_glue_job" "my_glue_job" {
  name     = "my-glue-job"
  role_arn = aws_iam_role.my_role.arn
  command {
    name            = "glueetl"
    script_location = "s3://my-bucket/glue-job-script.py"
  }
}

# Create KMS key
resource "aws_kms_key" "my_kms_key" {
  description             = "My KMS Key"
  deletion_window_in_days = 30
  tags = {
    Name = "MyKMSKey"
  }
}

# Create Application Load Balancer
resource "aws_lb" "my_load_balancer" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_security_group.id]
  subnets            = ["subnet-08293777b8ae1323e", "subnet-00b732a59f969805b"]
}

# Create Auto Scaling Group
resource "aws_autoscaling_group" "my_auto_scaling_group" {
  name                 = "my-auto-scaling-group"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = data.aws_subnets.example.ids
  launch_configuration = aws_launch_configuration.my_launch_configuration.name
}

# Create Launch Configuration
resource "aws_launch_configuration" "my_launch_configuration" {
  name_prefix   = "my-launch-configuration-"
  image_id      = "ami-0c4596ce1e7ae3e68" # Replace with your desired AMI ID
  instance_type = "t2.micro"
}
