variable "name" {
  type = string
}
variable "environment" {
  type = string
}
variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(any)
}

variable "repository_url" {
  type = string
}