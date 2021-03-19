
provider "aws" {
  region = "us-east-1"
  profile = "default"

}

# resource "aws_instance" "TerraformTest1" {
#     ami             = "ami-042e8287309f5df03"
#     instance_type   = "t3.micro"

#     tags = {
#         # Name = "UbuntuServer"
#   }
# }

resource "aws_vpc" "WatsonSkyVPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
      Name = "WatsonSky"
  }
}

resource "aws_subnet" "prod" {
  vpc_id     = aws_vpc.WatsonSkyVPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod"
  }
}

resource "aws_vpc" "PreProdVPC" {
  cidr_block = "10.1.0.0/16"

  tags = {
      Name = "PreProd"
  }
}

resource "aws_subnet" "preprod" {
  vpc_id     = aws_vpc.PreProdVPC.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "preprod"
  }
}