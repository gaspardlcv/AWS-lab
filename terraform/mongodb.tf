# Security Group - VULNÉRABLE
resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb-sg"
  description = "MongoDB Security Group - VULNERABLE"
  vpc_id      = aws_vpc.myvpc.id

  # SSH 
  ingress {
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    description = "SSH anywhere - VULNERABLE"
  }

  # MongoDB 
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.kubernetes_subnet_cidr]
    description = "MongoDB from Kubernetes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role avec permissions excessives - VULNÉRABILITÉ
resource "aws_iam_role" "mongodb_role" {
  name = "mongodb-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Permissions excessives - VULNÉRABILITÉ
resource "aws_iam_role_policy" "mongodb_policy" {
  name = "mongodb-excessive-permissions"
  role = aws_iam_role.mongodb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateVolume",
          "ec2:DescribeInstances",
          "iam:CreateUser",
          "iam:AttachUserPolicy"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.backups.arn}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "mongodb_profile" {
  name = "mongodb-instance-profile"
  role = aws_iam_role.mongodb_role.name
}

data "aws_ssm_parameter" "ubuntu_2204_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}


# EC2 obsolète
resource "aws_instance" "mongodb" {
  ami           = data.aws_ssm_parameter.ubuntu_2204_ami.value
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public_sub1.id
  
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.mongodb_profile.name
  
  key_name = "lab"

  user_data = <<-EOF
              #!/bin/bash
              # Installation MongoDB version obsolète (4.4 au lieu de 7.0)
              wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
              echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
              
              sudo apt-get update
              sudo apt-get install -y mongodb-org
              
              # Configuration MongoDB avec authentification
              sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
              echo "security:\n  authorization: enabled" | sudo tee -a /etc/mongod.conf
              
              sudo systemctl start mongod
              sudo systemctl enable mongod
              
              # Créer utilisateur admin
              mongosh <<MONGO
              use admin
              db.createUser({
                user: "admin",
                pwd: "P@ssw0rd123",
                roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]
              })
              MONGO
              
              # Script de backup quotidien
              cat > /usr/local/bin/mongodb-backup.sh <<'BACKUP'
              #!/bin/bash
              TIMESTAMP=$(date +%Y%m%d_%H%M%S)
              mongodump --out /tmp/backup-$TIMESTAMP
              tar -czf /tmp/mongodb-backup-$TIMESTAMP.tar.gz /tmp/backup-$TIMESTAMP
              aws s3 cp /tmp/mongodb-backup-$TIMESTAMP.tar.gz s3://${aws_s3_bucket.backups.id}/
              rm -rf /tmp/backup-$TIMESTAMP /tmp/mongodb-backup-$TIMESTAMP.tar.gz
              BACKUP
              
              chmod +x /usr/local/bin/mongodb-backup.sh
              
              # Cron job pour backup quotidien
              echo "0 2 * * * /usr/local/bin/mongodb-backup.sh" | crontab -
              EOF

  tags = {
    Name = "MongoDB-Server-Vulnerable"
  }
}