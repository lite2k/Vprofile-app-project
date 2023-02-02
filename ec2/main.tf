data "aws_ami" "ubuntu" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
data "aws_ami" "amazonLinux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*"]
  }
}
data "external" "myipVal" {
  program = ["bash", "-c", "./FetchIp.sh"]
}
resource "aws_security_group" "APPSG" {
  name        = "APP-SG"
  description = "Allows Connections to app01 instance"
  ingress {
    description = "Allows ssh connection from myip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.external.myipVal.result["internet_ip"]]
  }
  ingress {
    description     = "Allows connections to tomcat from loadbalancer"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [ var.elbSG-ID]
  }
  egress {
    description      = "Allows all egress connections"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name    = "APP-SG"
    Project = "Vprofile"
  }

}
resource "aws_security_group" "BCKSG" {
  name        = "BCK-SG"
  description = "Allows Connections to Backend services"
  ingress {
    description = "Allows ssh connection from myip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.external.myipVal.result["internet_ip"]]
  }
  ingress {
    description     = "Allows connections from tomcat to the database"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.APPSG.id]
  }
  ingress {
    ddescription    = "Allows connections from tomcat to memecached"
    from_port       = 11211
    to_port         = 11211
    protocol        = "tcp"
    security_groups = [aws_security_group.APPSG.id]
  }
  ingress {
    ddescription    = "Allows connections from tomcat to rabbit mq"
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.APPSG.id]
  }
  egress {
    description      = "Allows all egress connections"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name    = "BCK-SG"
    Project = "Vprofile"
  }

}
resource "aws_key_pair" "Project-Key" {
  key_name   = "project-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCbgHaWLec8NRvOUagtit1ZUyXJ9chXsDZKCA33RJPh+X/kkHbsA/A3taLGnN2ouqfqKCJPKoYijc6BD/Xd8bRvYgtYnLftuNU2GMsf3I4TMONY/8JXcBCyCcdf+o2FzlhoVkySeNALdz4wpbHXlK0Otv2RKhNbDVRWOiUL6TQm0P3ZmWn3m+St1gUhqIvUQ6dw/8bcxesAY1ru7VJp71Zg52CR86KffNKSMrLYDxKXzgwfkEQ8mOeAPl21xSlPkJqCcCHCWP0gs0AG9xxxM/usDwSSj2+a1T6K5YUkWgFRKTbkkHe9sdQKMEXz72khp7hRjyll0fttRbkr1G6qQoAmDryM80jmxZYBppMe2mt+63vUr2rTubbkqH8imvMM+tIUvf0hQicDTk/YKeqyVXrIrcjGHolE06RFhpbAm5tAAjwdA38xWwOF353RnhN80M+6e23P0KndrbiTwmg22xzG1HRo6pybL21Vv1QtQfTlF/1pZymlT5v2oQGI4w/wbI0= lite2k@AsusFx-506Li"
}

resource "aws_instance" "APP" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.APPSG.id]
  availability_zone      = "us-east-1a"
  key_name               = aws_key_pair.Project-Key.key_name
  tags = {
    Name    = "app01"
    Project = "Vprofile"
  }
}
resource "aws_instance" "DB" {
  ami                    = data.aws_ami.amazonLinux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.BCKSG.id]
  availability_zone      = "us-east-1a"
  key_name               = aws_key_pair.Project-Key.key_name
  tags = {
    Name    = "db01"
    Project = "Vprofile"
  }
}
resource "aws_instance" "RMQ" {
  ami                    = data.aws_ami.amazonLinux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.BCKSG.id]
  availability_zone      = "us-east-1a"
  key_name               = aws_key_pair.Project-Key.key_name
  tags = {
    Name    = "rmq01"
    Project = "Vprofile"
  }
}
resource "aws_instance" "MC" {
  ami                    = data.aws_ami.amazonLinux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.BCKSG.id]
  availability_zone      = "us-east-1a"
  key_name               = aws_key_pair.Project-Key.key_name
  tags = {
    Name    = "mc01"
    Project = "Vprofile"
  }
}
