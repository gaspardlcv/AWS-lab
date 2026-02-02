resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "backups" {
  bucket = "mongodb-backups-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "lab - MongoDB Backups - VULNERABLE PUBLIC BUCKET"
  }
}

# Configuration publique - VULNÉRABILITÉ
resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

