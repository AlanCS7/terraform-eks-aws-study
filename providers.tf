# Configurando/declarando os providers
terraform {
  required_version = "1.14.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.30.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.6.2"
    }
  }
}

# Configurando o provider AWS
provider "aws" {
  region = "us-east-1"
}
