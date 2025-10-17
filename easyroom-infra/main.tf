data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Generate an SSH key pair
resource "tls_private_key" "easyroom_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "easyroom_kp" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.easyroom_key.public_key_openssh
}

resource "local_file" "easyroom_private_key" {
  content  = tls_private_key.easyroom_key.private_key_pem
  filename = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0600"
}

# VPC
resource "aws_vpc" "easyroom_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "easyroom_igw" {
  vpc_id = aws_vpc.easyroom_vpc.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "easyroom_public_subnet" {
  vpc_id                  = aws_vpc.easyroom_vpc.id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true # Frontend and Backend will have public IPs

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Security Groups
resource "aws_security_group" "easyroom_frontend_sg" {
  name        = "${var.project_name}-frontend-sg"
  description = "Allow HTTP, HTTPS, and SSH to Frontend"
  vpc_id      = aws_vpc.easyroom_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow SSH from my IP"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-frontend-sg"
  }
}

resource "aws_security_group" "easyroom_backend_sg" {
  name        = "${var.project_name}-backend-sg"
  description = "Allow traffic from Frontend and SSH to Backend"
  vpc_id      = aws_vpc.easyroom_vpc.id

  ingress {
    from_port   = 3000 # Example Node.js port
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [aws_security_group.easyroom_frontend_sg.id]
    description = "Allow Backend API from Frontend SG"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow SSH from my IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-backend-sg"
  }
}

resource "aws_security_group" "easyroom_database_sg" {
  name        = "${var.project_name}-database-sg"
  description = "Allow traffic from Backend to MySQL, and SSH to Database"
  vpc_id      = aws_vpc.easyroom_vpc.id

  ingress {
    from_port   = 3306 # MySQL Port
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.easyroom_backend_sg.id]
    description = "Allow MySQL from Backend SG"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow SSH from my IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-database-sg"
  }
}

# EC2 Instances
resource "aws_instance" "frontend_server" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.easyroom_kp.key_name
  subnet_id       = aws_subnet.easyroom_public_subnet.id
  vpc_security_group_ids = [aws_security_group.easyroom_frontend_sg.id]
  associate_public_ip_address = true # Frontend needs public IP

  root_block_device {
    volume_size = var.frontend_ebs_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # Enforce IMDSv2
  }

  tags = {
    Name = "${var.project_name}-frontend"
  }
}

resource "aws_instance" "backend_server" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.easyroom_kp.key_name
  subnet_id       = aws_subnet.easyroom_public_subnet.id
  vpc_security_group_ids = [aws_security_group.easyroom_backend_sg.id]
  associate_public_ip_address = true # Backend needs public IP

  root_block_device {
    volume_size = var.backend_ebs_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # Enforce IMDSv2
  }

  tags = {
    Name = "${var.project_name}-backend"
  }
}

resource "aws_instance" "database_server" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.easyroom_kp.key_name
  subnet_id       = aws_subnet.easyroom_public_subnet.id
  vpc_security_group_ids = [aws_security_group.easyroom_database_sg.id]
  associate_public_ip_address = false # Database should NOT have public IP

  root_block_device {
    volume_size = var.database_ebs_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # Enforce IMDSv2
  }

  tags = {
    Name = "${var.project_name}-database"
  }
}

# Route Table for public subnet
resource "aws_route_table" "easyroom_public_rt" {
  vpc_id = aws_vpc.easyroom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.easyroom_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "easyroom_public_rta" {
  subnet_id      = aws_subnet.easyroom_public_subnet.id
  route_table_id = aws_route_table.easyroom_public_rt.id
}
