# VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# Public Subnets
output "public_subnet_ids" {
  description = "IDs of public subnets (ALB / EC2)"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# Private Subnets
output "private_subnet_ids" {
  description = "IDs of private subnets (RDS + Private EC2)"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# ALB
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

# Private EC2
output "private_ec2_private_ip" {
  description = "Private IP of the private EC2 instance (use this to SSH from bastion)"
  value       = aws_instance.private.private_ip
}

# RDS
output "rds_endpoint" {
  description = "RDS MySQL endpoint (accessible only within VPC)"
  value       = aws_db_instance.mysql.endpoint
  sensitive   = true
}

# Security Groups
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.web.id
}

output "ec2_security_group_id" {
  description = "ID of the public EC2 security group"
  value       = aws_security_group.ec2.id
}

output "private_ec2_security_group_id" {
  description = "ID of the private EC2 security group"
  value       = aws_security_group.private_ec2.id
}

output "db_security_group_id" {
  description = "ID of the DB security group"
  value       = aws_security_group.db.id
}
