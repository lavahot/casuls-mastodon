# Create a RDS database cluster

resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier     = "rds-cluster"
  engine                 = "aurora-postgresql"
  engine_mode            = "serverless"
  engine_version         = "11.16"
  master_username        = aws_secretsmanager_secret_version.db_user.secret_string
  master_password        = aws_secretsmanager_secret_version.db_password.secret_string
  storage_encrypted      = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  scaling_configuration {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 8
    seconds_until_auto_pause = 300
  }
  # Keep these parameters to avoid issues when destroying the cluster:
  # See https://stackoverflow.com/questions/50930470/terraform-error-rds-cluster-finalsnapshotidentifier-is-required-when-a-final-s
  skip_final_snapshot = true
  # backup_retention_period = 0
  apply_immediately = true
}

# Create a RDS database instance

# resource "aws_rds_cluster_instance" "rds_cluster_instance" {
#   identifier           = "rds-cluster-instance"
#   cluster_identifier   = aws_rds_cluster.rds_cluster.id
#   engine               = "aurora-postgresql"
#   engine_version       = "11.6"
#   instance_class       = "db.t2.micro"
#   db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
#   apply_immediately    = true
# }

# Create a security group for the RDS instance

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Security group for the RDS instance"
  vpc_id      = var.vpc_id
}

# Create a security group rule for the RDS instance that allows incoming connections from the ecs security group

resource "aws_security_group_rule" "rds_sg" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.ecs_tasks.id
}

# Create a random password for the RDS instance

resource "random_password" "rds_cluster_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a subnet group for the RDS instance

resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "rds_subnet_group"
  description = "Subnet group for the RDS instance"
  subnet_ids  = var.private_subnet_ids
}

# Create a cloudwatch log group for the RDS instance

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/rds/mastodon"
  retention_in_days = 30
}
