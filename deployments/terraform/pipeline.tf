resource "aws_codecommit_repository" "code_repository" {
  repository_name = "${local.name}-git-repository"
}

resource "aws_ecr_repository" "container_repository" {
  name                 = "${local.name}-ecr-repository"
  image_tag_mutability = "MUTABLE"
}

# resource "aws_codepipeline" "codepipeline" {
#   name = "pipeline"


#   stage {
#     name = "Source"

#   }

# #   stage {
# #     name = "Build"
# #   }

#     # stage {
#     #     name = "Test"
#     # }

#     # stage {
#     #   name = "Deploy Staging"
#     # }

#     # stage {
#     #     name = "Deploy Production"
#     # }
# }