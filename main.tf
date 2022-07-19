resource "aws_vpc" "myvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Dev"
  }

}
resource "aws_subnet" "pub" {
  vpc_id                  = aws_vpc.myvpc.id
  map_public_ip_on_launch = true
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1a"
  tags = {
    Name = "dev-public"
  }

}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "igw"
  }
}
resource "aws_route_table" "dev_pub_rt" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    "Name" = "pub_rt"
  }

}
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.dev_pub_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

}
resource "aws_route_table_association" "pub_assoc" {
  subnet_id      = aws_subnet.pub.id
  route_table_id = aws_route_table.dev_pub_rt.id

}
resource "aws_security_group" "allow_tls" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "ssh from VPC"
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


}
resource "aws_key_pair" "ssh-key" {
    key_name = "devkey"
    public_key = file("~/.ssh/devkey.pub")
  
}
data "aws_ami" "server_ami"{
    most_recent = true
    owners = ["099720109477"]

    filter{
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }
}

resource "aws_instance" "Dev_node" {
    instance_type = "t2.micro"
    ami = data.aws_ami.server_ami.id
    key_name = aws_key_pair.ssh-key.id
    vpc_security_group_ids = [aws_security_group.allow_tls.id]
    subnet_id = aws_subnet.pub.id
    user_data = file("userdata.tpl")

    root_block_device {
      volume_size = 10
    }

    tags = {
      "Name" = "DEV-node"
    }
    provisioner "local-exec" {
        command = templatefile("windows-ssh-config.tpl",{
            hostname = self.public_ip ,
            user = "ubuntu",
            identityfile = "~/.ssh/devkey"
        })
        interpreter = ["Powershell" , "-command"]
      
    }
}

output "pubip" {
  value = aws_instance.Dev_node.public_ip
  
}



   