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
    security_groups = [module.eks.node_security_group_id]
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
  
  key_name = "labfinal"
  user_data_replace_on_change = true

# IMPORTANT: Le heredoc doit commencer à la colonne 0, pas indenté !
  user_data = <<-EOF
#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== MongoDB Installation Script Started at $(date) ==="

echo "=== Installing libssl1.1 ==="
cd /tmp
wget -q http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb

echo "=== Adding MongoDB Repository ==="
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list

echo "=== Installing MongoDB and AWS CLI ==="
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y mongodb-org awscli

echo "=== Creating MongoDB Configuration ==="
cat > /etc/mongod.conf <<'MONGODCONF'
storage:
  dbPath: /var/lib/mongodb
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
net:
  port: 27017
  bindIp: 0.0.0.0
processManagement:
  timeZoneInfo: /usr/share/zoneinfo
security:
  authorization: enabled
MONGODCONF

echo "=== Starting MongoDB ==="
systemctl daemon-reload
systemctl start mongod
systemctl enable mongod

echo "Waiting for MongoDB to start..."
for i in {1..30}; do
  if systemctl is-active --quiet mongod; then
    echo "MongoDB is running"
    break
  fi
  sleep 2
done

sleep 10

echo "=== Creating MongoDB Admin User ==="
mongo --eval "
  db = db.getSiblingDB('admin');
  db.createUser({
    user: 'admin',
    pwd: '${random_password.mongodb_password.result}',
    roles: [ 
      { role: 'userAdminAnyDatabase', db: 'admin' }, 
      'readWriteAnyDatabase' 
    ]
  });
" || echo "User creation failed or user already exists"

echo "=== Creating Backup Script ==="
cat > /usr/local/bin/mongodb-backup.sh <<'BACKUP'
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mongodump -u admin -p '${random_password.mongodb_password.result}' --authenticationDatabase admin --out /tmp/backup-$TIMESTAMP
tar -czf /tmp/mongodb-backup-$TIMESTAMP.tar.gz -C /tmp backup-$TIMESTAMP
aws s3 cp /tmp/mongodb-backup-$TIMESTAMP.tar.gz s3://${aws_s3_bucket.backups.id}/ --region eu-west-1
rm -rf /tmp/backup-$TIMESTAMP /tmp/mongodb-backup-$TIMESTAMP.tar.gz
echo "Backup completed: $TIMESTAMP" >> /var/log/mongodb-backup.log
BACKUP

chmod +x /usr/local/bin/mongodb-backup.sh

echo "=== Setting up Cron Job ==="
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/mongodb-backup.sh") | crontab -

echo "=== Verifying MongoDB Installation ==="
systemctl status mongod >> /var/log/user-data.log 2>&1
mongo --version >> /var/log/user-data.log 2>&1

echo "=== MongoDB Installation Completed at $(date) ==="
echo "SUCCESS" > /var/log/mongodb-install-complete
EOF

  tags = {
    Name = "MongoDB-Server-Vulnerable"
  }
}