provider "aws" {
  region = "us-east-1"
  profile = "default"

}

resource "aws_vpc" "prod" {
  cidr_block = "10.0.0.0/16"

  tags = {
      Name = "production"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "internet-gateway"
  }
}

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}

resource "aws_subnet" "subnet1" {
    vpc_id              = aws_vpc.prod.id
    cidr_block          = "10.0.1.0/24"
    availability_zone   = "us-east-1a"

    tags = {
        Name = "prod-subnet"
    }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.prod-route-table.id
}

resource "aws_security_group" "allow-web" {
  name        = "allow_web"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "webserver-nic" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow-web.id]

}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.webserver-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

resource "aws_instance" "web-server" {
  ami               = "ami-042e8287309f5df03"
  instance_type     = "t2.micro"
  key_name      	  = "watsonsky"
  
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.webserver-nic.id
  }

  tags = {
      # Name = "WebServer"
  }

  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  sudo sysemctl start apache2
  sudo bash -c 'echo "<h1>Welcome to the WatsonSky Webserver</h1><br><br><br><p>Congigured using Terraform on AWS</p>" > /var/www/html/index.html'
  EOF
}