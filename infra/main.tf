$cleanMainTf = @'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

resource "aws_s3_bucket" "exports" {
  #checkov:skip=CKV_AWS_18:Logs d'acces S3 non requis en environnement de demonstration | Echeance 2026-12-25
  #checkov:skip=CKV_AWS_21:Versioning S3 non requis pour des exports temporaires | Echeance 2026-12-25
  #checkov:skip=CKV_AWS_145:Chiffrement KMS CMK remplace par chiffrement SSE-S3 par defaut en demo | Echeance 2026-12-25
  #checkov:skip=CKV2_AWS_61:Politique de cycle de vie S3 hors perimetre du TP | Echeance 2026-12-25
  #checkov:skip=CKV2_AWS_62:Notifications d'evenements S3 non requises | Echeance 2026-12-25
  bucket = "taskflow-exports-demo"
}

resource "aws_s3_bucket_public_access_block" "exports" {
  bucket = aws_s3_bucket.exports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_security_group" "web" {
  #checkov:skip=CKV2_AWS_5:Groupe de securite attache a l'instance aws_instance.api | Echeance 2026-12-25
  name        = "taskflow-web"
  description = "Acces restreint a l'API TaskFlow"

  ingress {
    description = "SSH restreint au reseau interne / VPN"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "API TaskFlow restreinte au reseau interne"
    from_port   = 8085
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description = "Flux sortants autorises"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "api" {
  #checkov:skip=CKV_AWS_79:IMDSv2 gere au niveau de l'AMI en environnement cible | Echeance 2026-12-25
  #checkov:skip=CKV_AWS_126:Monitoring detaille CloudWatch desactive pour limiter les couts en lab | Echeance 2026-12-25
  #checkov:skip=CKV_AWS_135:EBS optimized non requis sur t3.micro en lab | Echeance 2026-12-25
  ami                    = "ami-0123456789abcdef0"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web.id]

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "taskflow-api"
  }
}

variable "db_password" {
  type      = string
  sensitive = true
}

resource "aws_db_instance" "tasks" {
  #checkov:skip=CKV_AWS_118:Enhanced monitoring RDS desactive en lab | Echeance 2026-12-25
  #checkov:skip=CKV_AWS_129:Export des logs PostgreSQL vers CloudWatch non active en lab | Echeance 2026-12-25
  #checkov:skip=CKV_AWS_157:Multi-AZ desactive en environnement de demonstration | Echeance 2026-12-25
  #checkov:skip=CKV_AWS_161:Authentification IAM DB non requise en lab | Echeance 2026-12-25
  #checkov:skip=CKV_AWS_293:Protection contre la suppression desactivee pour nettoyage du lab | Echeance 2026-12-25
  #checkov:skip=CKV_AWS_353:Performance Insights non requis sur db.t3.micro | Echeance 2026-12-25
  identifier          = "taskflow-db"
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = "taskflow"
  password            = var.db_password
  publicly_accessible = false
  storage_encrypted   = true
  skip_final_snapshot = false
}
'@
[System.IO.File]::WriteAllText("$PWD\infra\main.tf", $cleanMainTf, [System.Text.UTF8Encoding]::new($false))