# EFS definition to be used in the task definition

resource "aws_efs_file_system" "mastofs" {
  encrypted = true
}

# create a backup policy for the EFS file system

resource "aws_efs_backup_policy" "masto_fs_bp" {
  file_system_id = aws_efs_file_system.mastofs.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_access_point" "masto_fs_ap" {
  file_system_id = aws_efs_file_system.mastofs.id
}

# Create a efs mount target for each subnet in the VPC

resource "aws_efs_mount_target" "mast_fs_mt" {
  for_each        = toset(var.public_subnet_ids)
  file_system_id  = aws_efs_file_system.mastofs.id
  subnet_id       = each.key
  security_groups = [aws_security_group.efs_sg.id]
}

# Create a security group for the EFS mount targets

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = var.vpc_id
}

# Create a security group rule to allow NFS traffic from the VPC

resource "aws_security_group_rule" "efs_sg_rule" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs_sg.id
  source_security_group_id = aws_security_group.ecs_tasks.id
}

# A Security group rule for encrypted EFS traffic

resource "aws_security_group_rule" "efs_sg_rule_secure" {
  type                     = "ingress"
  from_port                = 2999
  to_port                  = 2999
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs_sg.id
  source_security_group_id = aws_security_group.ecs_tasks.id
}
