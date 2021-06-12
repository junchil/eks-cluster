output "kubeconfig" {
  value = module.eks.kubeconfig
}

output "config_map_aws_auth" {
  value = module.eks.config_map_aws_auth
}

output "Kubenetes-server-ip" {
  value = module.bastion-host.elastic_ip
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "helm_values" {
  value = <<EOF
  certificateArn: ${aws_acm_certificate.cert.arn}
  EOF

}