# I imported the existing VPC into the state so this module could take over its management
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  # Give the VPC a friendly/recognisable name
  name = "hello-world-vpc"
  cidr = "172.31.0.0/16"

  azs             = ["eu-south-1a", "eu-south-1b", "eu-south-1c"]
  public_subnets  = ["172.31.101.0/24", "172.31.102.0/24", "172.31.103.0/24"]
  private_subnets = ["172.31.1.0/24", "172.31.2.0/24", "172.31.3.0/24"]

  # Enable the NAT gateway so ECS can reach ECR to pull images
  # Also allows services running in private subnets to make secure outbound requests
  enable_nat_gateway = true

  # Add tags to the public/private subnets so that can be identified via data sources
  public_subnet_tags = {
    Tier = "Public"
  }

  private_subnet_tags = {
    Tier = "Private"
  }

  tags = {
    Terraform = "true"
    App       = var.project_name
  }
}

# Permits traffic to the ALB on port 80 for regular HTTP traffic
# Could be expanded to include port 443 for HTTPS if required
resource "aws_security_group" "alb" {
  name        = "alb-access"
  description = "Allow inbound traffic to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Permits the ALB to access the running tasks within ECS which have been configured to port 8080
resource "aws_security_group" "container" {
  name        = "container-access"
  description = "Allow ALB Target Groups to directly access a container in ECS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
