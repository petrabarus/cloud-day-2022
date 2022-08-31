
locals {
  account_id = data.aws_caller_identity.current.account_id
  codebuild_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "codebuild_role" {
  name = "${local.name}-codebuild-build-role"

  assume_role_policy = local.codebuild_assume_role_policy
}

resource "aws_iam_role_policy" "codebuild_role_policy" {
  name = "${local.name}-codebuild-role-policy"
  role = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ],
        Effect = "Allow"
        Resource = [
          aws_kms_key.encryption_key.arn
        ]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.codepipeline_bucket.arn}",
          "${aws_s3_bucket.codepipeline_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ],
        Effect = "Allow",
        Resource = [
          aws_ecr_repository.container_repository.arn
        ]
      },
      {
        Action = [
          "ecr:GetAuthorizationToken",

        ],
        Effect = "Allow"
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_codebuild_project" "codebuild_build" {
  name           = "${local.name}-2-codebuild-build"
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.encryption_key.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.container_repository.repository_url
    }

    environment_variable {
      name  = "REPOSITORY_DOMAIN"
      value = "${local.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = "app"
    }
  }

  source {
    buildspec = templatefile("./scripts/buildspec_2_build.tpl.yml", {

    })
    type = "CODEPIPELINE"
  }
}

resource "aws_codebuild_project" "codebuild_test" {
  name           = "${local.name}-3-codebuild-test"
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.encryption_key.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    buildspec = templatefile("./scripts/buildspec_3_test.tpl.yml", {

    })
    type = "CODEPIPELINE"
  }
}

resource "aws_codebuild_project" "codebuild_static_analysis" {
  name           = "${local.name}-4-codebuild-static-analysis"
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.encryption_key.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "SONAR_HOST_URL"
      value = "http://${aws_instance.sonarqube.public_dns}/"
    }

    environment_variable {
      name  = "SONAR_LOGIN"
      value = var.sonar_login
    }

    environment_variable {
      name  = "SONAR_PROJECT_KEY"
      value = var.sonar_project_key
    }
  }

  source {
    buildspec = templatefile("./scripts/buildspec_4_static_analysis.tpl.yml", {

    })
    type = "CODEPIPELINE"
  }
}

resource "aws_codebuild_project" "codebuild_security_analysis" {
  name           = "${local.name}-6-codebuild-security-analysis"
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.encryption_key.arn


  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true


    environment_variable {
      name  = "STAGING_SITE_URL"
      value = module.cluster["staging"].site_url
    }
  }

  source {
    buildspec = templatefile("./scripts/buildspec_6_security_analysis.tpl.yml", {

    })
    type = "CODEPIPELINE"
  }
}