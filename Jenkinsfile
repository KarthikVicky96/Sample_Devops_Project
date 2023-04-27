# Define the source code repository
resource "aws_codecommit_repository" "terraform_repo" {
  name = "terraform-repo"
}

# Define the AWS CodeBuild project
resource "aws_codebuild_project" "terraform_build" {
  name        = "terraform-build"
  description = "Builds and deploys Terraform infrastructure"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    privileged_mode             = true
    environment_variable       = [{ name = "AWS_DEFAULT_REGION", value = "us-east-1" }]
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.terraform_repo.clone_url_http
    buildspec       = "terraform/buildspec.yml"
    git_clone_depth = 1
  }

  service_role = aws_iam_role.codebuild.arn
}

# Define the AWS CodePipeline pipeline
resource "aws_codepipeline" "terraform_pipeline" {
  name     = "terraform-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = "terraform-bucket"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name     = "SourceAction"
      category = "Source"

      owner = "AWS"
      provider = "CodeCommit"

      version = "1"

      configuration = {
        RepositoryName = aws_codecommit_repository.terraform_repo.name
      }

      output_artifacts = ["SourceOutput"]
    }
  }

  stage {
    name = "Build"

    action {
      name            = "BuildAction"
      category        = "Build"
      input_artifacts = ["SourceOutput"]

      owner     = "AWS"
      provider  = "CodeBuild"
      version   = "1"

      configuration = {
        ProjectName = aws_codebuild_project.terraform_build.name
      }

      output_artifacts = ["BuildOutput"]
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      input_artifacts = ["BuildOutput"]

      owner    = "AWS"
      provider = "CloudFormation"
      version  = "1"

      configuration = {
        ActionMode        = "CREATE_UPDATE"
        Capabilities      = "CAPABILITY_IAM"
        RoleArn           = aws_iam_role.cloudformation_deploy.arn
        StackName         = "my-stack"
        TemplatePath      = "BuildOutput::template.yaml"
        TemplateConfiguration = "BuildOutput::template-configuration.json"
        ParameterOverrides = "{\"InstanceType\":\"t2.micro\"}"
      }
    }
  }
}
