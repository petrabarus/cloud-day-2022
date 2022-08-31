resource "aws_codecommit_repository" "code_repository" {
  repository_name = "${local.name}-git-repository"
}

resource "aws_ecr_repository" "container_repository" {
  name                 = "${local.name}-ecr-repository"
  image_tag_mutability = "MUTABLE"
}

resource "aws_codepipeline" "codepipeline" {
  name = "${local.name}-codepipeline"

  role_arn = aws_iam_role.codepipeline_role.arn


  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "1_Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      output_artifacts = ["source_output"]
      provider         = "CodeCommit"
      version          = "1"

      configuration = {
        RepositoryName = aws_codecommit_repository.code_repository.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "2_Build"

    action {
      name             = "${local.name}-build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_build.name
      }
    }
  }

  stage {
    name = "3_Test"

    action {
      name             = "${local.name}-test"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["test_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_test.name
      }
    }
  }

  stage {
    name = "4_Static_Analysis"

    action {
      name             = "${local.name}-static-analysis"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["static_analysis_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_static_analysis.name
      }
    }
  }

  stage {
    name = "5_Staging_Deployment"

    action {
      name            = "${local.name}-5-staging-deployment"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = module.cluster["staging"].cluster_name
        ServiceName = module.cluster["staging"].service_name
      }
    }
  }

  stage {
    name = "6_Security_Analysis"

    action {
      name             = "${local.name}-security-analysis"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["build_output"]
      output_artifacts = ["security_analysis_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_security_analysis.name
      }
    }
  }

  stage {
    name = "7_Production_Deployment"

    action {
      name            = "${local.name}-7-production-deployment"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = module.cluster["production"].cluster_name
        ServiceName = module.cluster["production"].service_name
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "${local.name}-codepipeline-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${local.name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${local.name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  //https://docs.aws.amazon.com/codepipeline/latest/userguide/security-iam.html#how-to-update-role-new-services
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ],
        Resource : [
          "${aws_s3_bucket.codepipeline_bucket.arn}",
          "${aws_s3_bucket.codepipeline_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:UploadArchive",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:CancelUploadArchive"
        ]
        Resource = [
          aws_codecommit_repository.code_repository.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        Resource = [
          aws_codebuild_project.codebuild_build.arn,
          aws_codebuild_project.codebuild_test.arn,
          aws_codebuild_project.codebuild_static_analysis.arn,
          aws_codebuild_project.codebuild_security_analysis.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:UpdateService"
        ],
        Resource = [
          module.cluster["staging"].service_arn,
          module.cluster["production"].service_arn
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
          "ecr:UploadLayerPart"
        ],
        Effect = "Allow",
        Resource = [
          aws_ecr_repository.container_repository.arn
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
          "iam:PassRole"
        ],
        Effect = "Allow"
        Resource = [
          "*"
        ]
      },
      {
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision",
          //
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
        ],
        Effect = "Allow"
        Resource = [
          "*"
        ]
      }
    ]
  })
}
