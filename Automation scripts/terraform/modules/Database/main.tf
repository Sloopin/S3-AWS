resource "aws_db_instance" "webappdb" {
  identifier             = "webappdb"
  name                   = "webappdb"
  instance_class         = "db.t2.micro"
  allocated_storage      = 5
  engine                 = "mysql"
  engine_version         = "8.0"
  username               = "admin"
  password               = "Password01"
  db_subnet_group_name   = "default-vpc-0fa0def37d2c6b064"
  vpc_security_group_ids = ["sg-0beb2784ea73b0e14"]
  parameter_group_name   = "default.mysql8.0"
  availability_zone      = "eu-central-1a"
  port                   = "3306"
  publicly_accessible    = true
  skip_final_snapshot    = true
}
