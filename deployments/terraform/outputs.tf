output "sonarqube_address" {
    depends_on = [
      aws_eip.sonarqube_eip,
    ]
    
    value = "http://${aws_instance.sonarqube.public_dns}/"
}