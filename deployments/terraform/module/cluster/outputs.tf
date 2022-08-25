output "load_balancer_url" {
  value = "http://${aws_lb.main_load_balancer.dns_name}/"
}