# RDS PostgreSQL module
# Subnet group restricting the database to the supplied private subnets.
resource "aws_db_subnet_group" "database_subnet_group" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name         = "${var.project}-${var.environment}-db-subnet-group"
    Owner        = var.owner
    Project      = var.project
    Environment  = var.environment
    "aws-apn-id" = var.aws_apn_id
  }
}

resource "aws_db_parameter_group" "database" {
  name   = "${var.project}-${var.environment}-postgres15-params"
  family = "postgres15"

  parameter {
    name         = "rds.force_ssl"
    value        = "0"
    apply_method = "pending-reboot"
  }

  tags = {
    Name         = "${var.project}-${var.environment}-postgres15-params"
    Owner        = var.owner
    Project      = var.project
    Environment  = var.environment
    "aws-apn-id" = var.aws_apn_id
  }
}

# Private PostgreSQL database instance for the regional environment.
resource "aws_db_instance" "database" {
  identifier             = "${var.project}-${var.environment}-postgres"
  allocated_storage      = var.allocated_storage
  engine                 = "postgres"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  port                   = var.db_port
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  parameter_group_name   = aws_db_parameter_group.database.name
  vpc_security_group_ids = var.security_group_ids
  skip_final_snapshot    = true
  multi_az               = var.multi_az
  publicly_accessible    = false

  tags = {
    Name         = "${var.project}-${var.environment}-postgres"
    Owner        = var.owner
    Project      = var.project
    Environment  = var.environment
    "aws-apn-id" = var.aws_apn_id
  }
}
