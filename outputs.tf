# ============================================================================
# LOCALS - Variáveis Locais
# ============================================================================

# Gera o arquivo de configuração do Kubernetes (kubeconfig)
locals {
  kubeconfig = yamlencode({
    apiVersion = "v1"     # Versão da API do Kubernetes
    kind       = "Config" # Tipo de arquivo de configuração

    # Configurações dos clusters disponíveis
    clusters = [
      {
        cluster = {
          server                     = aws_eks_cluster.cluster.endpoint                      # URL do API server do EKS
          certificate-authority-data = aws_eks_cluster.cluster.certificate_authority[0].data # Certificado TLS
        }
        name = "kubernetes" # Nome interno do cluster
      }
    ]

    # Contextos de acesso (combina cluster + usuário)
    contexts = [
      {
        context = {
          cluster = "kubernetes"                 # Cluster que será usado
          user    = aws_eks_cluster.cluster.name # Usuário de autenticação
        }
        name = aws_eks_cluster.cluster.name # Nome do contexto
      }
    ]

    current-context = aws_eks_cluster.cluster.name # Contexto ativo por padrão
    preferences     = {}                           # Preferências do usuário (vazio)

    # Configurações de autenticação dos usuários
    users = [
      {
        name = aws_eks_cluster.cluster.name # Nome do usuário
        user = {
          exec = {
            apiVersion = "client.authentication.k8s.io/v1beta1"        # Versão da API de autenticação
            command    = "aws-iam-authenticator"                       # Comando para obter token
            args       = ["token", "-i", aws_eks_cluster.cluster.name] # Argumentos do comando
          }
        }
      }
    ]
  })
}

# ============================================================================
# LOCAL FILE - Arquivo Local
# ============================================================================
# Cria o arquivo kubeconfig no diretório do projeto
resource "local_file" "kubeconfig" {
  content  = local.kubeconfig # Conteúdo gerado pelo local acima
  filename = "kubeconfig"     # Nome do arquivo
}
