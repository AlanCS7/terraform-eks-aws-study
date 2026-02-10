# ============================================================================
# SECURITY GROUP - Grupo de Segurança
# ============================================================================
# Funciona como um firewall virtual para controlar o tráfego de entrada e saída
# dos recursos na VPC (EC2, RDS, ELB, etc.)
resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.new-vpc.id # ID da VPC onde o security group será criado

  # REGRAS DE SAÍDA (EGRESS)
  # Permite todo tráfego de saída das instâncias
  egress {
    from_port       = 0             # Porta inicial (0 = todas as portas)
    to_port         = 0             # Porta final (0 = todas as portas)
    protocol        = "-1"          # Protocolo (-1 = todos os protocolos: TCP, UDP, ICMP)
    cidr_blocks     = ["0.0.0.0/0"] # Destino (0.0.0.0/0 = qualquer endereço IP)
    prefix_list_ids = []            # Lista de prefixos (vazia = não utilizada)
  }

  tags = {
    Name = "${var.prefix}-sg" # Nome do security group usando prefixo da variável
  }
}

# ============================================================================
# IAM ROLE - Função IAM para o Cluster EKS
# ============================================================================
# Define permissões que o serviço EKS pode assumir para gerenciar recursos AWS
resource "aws_iam_role" "cluster" {
  name = "${var.prefix}-${var.cluster_name}-role-cluster" # Nome único usando prefixo e nome do cluster

  # Política de confiança (Trust Policy)
  # Define quem pode assumir esta role (neste caso, o serviço EKS)
  assume_role_policy = jsonencode({
    Version = "2012-10-17" # Versão da política IAM
    Statement = [
      {
        Effect = "Allow" # Permite a ação
        Principal = {
          Service = "eks.amazonaws.com" # Serviço EKS pode assumir esta role
        }
        Action = "sts:AssumeRole" # Ação de assumir a role
      }
    ]
  })
}

# ============================================================================
# IAM ROLE POLICY ATTACHMENT - Anexo de Política IAM
# ============================================================================
# Anexa uma política AWS gerenciada à role do cluster
# Concede permissões específicas para o EKS gerenciar recursos VPC
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  role       = aws_iam_role.cluster.name                                # Nome da role que receberá a política
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController" # ARN da política AWS
}

# ============================================================================
# IAM ROLE POLICY ATTACHMENT - Anexo de Política IAM
# ============================================================================
# Anexa uma política AWS gerenciada à role do cluster
# Concede permissões específicas para o EKS gerenciar recursos do cluster
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  role       = aws_iam_role.cluster.name                        # Nome da role que receberá a política
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" # ARN da política AWS
}

# ============================================================================
# CLOUDWATCH LOG GROUP - Grupo de Logs
# ============================================================================
# Armazena logs do cluster EKS para monitoramento e debugging
resource "aws_cloudwatch_log_group" "log" {
  name              = "/aws/eks/${var.prefix}-${var.cluster_name}/cluster" # Caminho do log no CloudWatch
  retention_in_days = var.retention_in_days                                # Período de retenção dos logs (default: 30 dias)
}

# ============================================================================
# EKS CLUSTER - Cluster Kubernetes
# ============================================================================
# Cria o cluster gerenciado Kubernetes na AWS
resource "aws_eks_cluster" "cluster" {
  name                      = "${var.prefix}-${var.cluster_name}" # Nome do cluster
  role_arn                  = aws_iam_role.cluster.arn            # ARN da role IAM para o cluster
  enabled_cluster_log_types = ["api", "audit"]                    # Tipos de logs habilitados

  # Configuração de rede VPC
  vpc_config {
    endpoint_public_access = true                            # Permite acesso público ao API server
    subnet_ids             = aws_subnet.subnets[*].id        # IDs das sub-redes onde o cluster será executado
    security_group_ids     = [aws_security_group.cluster.id] # Security group para o cluster
  }

  # Dependências explícitas para garantir ordem de criação
  depends_on = [
    aws_cloudwatch_log_group.log,                                  # Log group deve existir antes
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy, # Políticas IAM devem estar anexadas
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController
  ]
}
