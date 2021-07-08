output "elastic_ip" {
  value = aws_eip.ip.public_ip
}

output "kubernetes_server_instance_sg" {
  value = aws_security_group.kubernetes_server_instance_sg.id
}

