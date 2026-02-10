# Terraform EKS AWS Study

Projeto de aprendizado para criar um cluster Kubernetes gerenciado na AWS usando Terraform.

## O que foi implementado:

- VPC com sub-redes públicas
- Cluster EKS com logging
- Node groups com auto-scaling
- Security groups e IAM roles
- Kubeconfig gerado automaticamente

## Como usar:

1. Configure suas credenciais AWS
2. Execute `terraform init`
3. Execute `terraform apply`
