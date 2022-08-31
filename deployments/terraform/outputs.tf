output "sonarqube_address" {
  depends_on = [
    aws_eip.sonarqube_eip,
  ]

  value = "http://${aws_instance.sonarqube.public_dns}/"
}

output "staging_site_url" {
  value = module.cluster["staging"].site_url
}

output "production_site_url" {
  value = module.cluster["production"].site_url
}