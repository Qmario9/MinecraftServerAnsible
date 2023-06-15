terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["credentials"]
  profile = "default"
  
}
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair"  # Replace with your desired key pair name
  public_key = file("your_public_key_file")  # Replace with the path to your public key file
}
resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"  
  description = "My security group"

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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

  # Other security group configuration parameters...
}
variable "public_key_path" {
  description = "Path to the public SSH key"
  default     = "you_public_key_file"
}
variable "myuser" {
  description = "Username of the non-sudo user"
  type        = string
  default     = "ubuntu"
}
resource "aws_instance" "app_server" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t3.medium"
  key_name = aws_key_pair.my_key_pair.key_name

  vpc_security_group_ids = [aws_security_group.my_security_group.id]

  tags = {
    Name = var.instance_name
  }
  provisioner "file" {
    source="scripts/script.sh"
    destination="/tmp/script.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo bash /tmp/script.sh"
    ]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("your_private_key_file")
    host        = self.public_ip
  }
  

}

output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
}
