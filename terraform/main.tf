provider "aws" {
  region = "ap-south-1"
}

# -----------------------
# ECR Repository
# -----------------------
resource "aws_ecr_repository" "repo" {
  name = "health-care"
}

# -----------------------
# ECS Cluster
# -----------------------
resource "aws_ecs_cluster" "main" {
  name = "healthcare-cluster"
}

# -----------------------
# IAM Role for ECS Task Execution
# -----------------------
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----------------------
# Security Group
# -----------------------
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow traffic to ECS containers"
  vpc_id      = "<your-vpc-id>"  # Replace with your actual VPC ID

  ingress {
    from_port   = 8000
    to_port     = 8000
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

# -----------------------
# ECS Task Definition
# -----------------------
resource "aws_ecs_task_definition" "healthcare" {
  family                   = "healthcare-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "healthcare"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
    }
  ])
}

# -----------------------
# ECS Service
# -----------------------
resource "aws_ecs_service" "healthcare" {
  name            = "healthcare-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.healthcare.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["<your-subnet-id>"] # Replace with a public subnet ID
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_attach]
}
