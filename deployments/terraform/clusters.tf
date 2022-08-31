
locals {
  clusters = {
    staging = {
      environment = "staging"
    }
    production = {
      environment = "production"
    }
  }
}


module "cluster" {
  depends_on = [
    aws_ecr_repository.container_repository,
  ]

  for_each = local.clusters
  source   = "./module/cluster"

  name           = "${local.name}-${each.key}"
  environment    = each.value.environment
  vpc_id         = aws_vpc.main.id
  public_subnets = aws_subnet.public
  repository_url = aws_ecr_repository.container_repository.repository_url
}

