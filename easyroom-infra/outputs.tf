output "frontend_public_ip" {
  description = "Public IP address of the Frontend EC2 instance"
  value       = aws_instance.frontend_server.public_ip
}

output "backend_public_ip" {
  description = "Public IP address of the Backend EC2 instance (for testing/limited access)"
  value       = aws_instance.backend_server.public_ip
}

output "frontend_ssh_command" {
  description = "SSH command to connect to the Frontend EC2 instance"
  value       = "ssh -i ${path.module}/${var.project_name}-key.pem ubuntu@${aws_instance.frontend_server.public_ip}"
}

output "backend_ssh_command" {
  description = "SSH command to connect to the Backend EC2 instance"
  value       = "ssh -i ${path.module}/${var.project_name}-key.pem ubuntu@${aws_instance.backend_server.public_ip}"
}

output "database_private_ip" {
  description = "Private IP address of the Database EC2 instance"
  value       = aws_instance.database_server.private_ip
}

output "database_ssh_command" {
  description = "SSH command to connect to the Database EC2 instance (using its private IP, typically from backend/frontend server)"
  value       = "ssh -i ${path.module}/${var.project_name}-key.pem ubuntu@${aws_instance.database_server.private_ip}"
}

output "private_key_file" {
  description = "Path to the generated private key file"
  value       = local_file.easyroom_private_key.filename
}
