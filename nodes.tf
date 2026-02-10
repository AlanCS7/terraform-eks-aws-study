# ============================================================================
# IAM ROLE - Função IAM para Worker Nodes
# ============================================================================
# Define permissões que as instâncias EC2 (worker nodes) podem assumir
resource "aws_iam_role" "node" {
  name = "${var.prefix}-${var.cluster_name}-role-node" # Nome único para role dos nodes

  # Política de confiança (Trust Policy)
  # Define que instâncias EC2 podem assumir esta role
  assume_role_policy = jsonencode({
    Version = "2012-10-17" # Versão da política IAM
    Statement = [
      {
        Effect = "Allow" # Permite a ação
        Principal = {
          Service = "ec2.amazonaws.com" # Instâncias EC2 podem assumir esta role
        }
        Action = "sts:AssumeRole" # Ação de assumir a role
      }
    ]
  })
}

# ============================================================================
# IAM ROLE POLICY ATTACHMENTS - Anexos de Políticas IAM
# ============================================================================

# Política para Worker Nodes do EKS
resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.node.name                              # Nome da role que receberá a política
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" # Permissões básicas de worker node
}

# Política para CNI (Container Network Interface)
resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.node.name                         # Nome da role que receberá a política
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" # Permissões para gerenciar rede de pods
}

# Política para acesso ao ECR (Elastic Container Registry)
resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.node.name                                       # Nome da role que receberá a política
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # Acesso de leitura ao ECR
}

# ============================================================================
# EKS NODE GROUP - Grupo de Worker Nodes
# ============================================================================

# Primeiro grupo de nodes (usa tipo de instância padrão)
resource "aws_eks_node_group" "node-1" {
  cluster_name    = aws_eks_cluster.cluster.name # Nome do cluster EKS
  node_group_name = "node-1"                     # Nome do grupo de nodes
  node_role_arn   = aws_iam_role.node.arn        # ARN da role IAM para os nodes
  subnet_ids      = aws_subnet.subnets[*].id     # Sub-redes onde os nodes serão criados

  # Configuração de auto-scaling
  scaling_config {
    desired_size = var.node_group_desired_size # Número desejado de nodes (default: 2)
    max_size     = var.node_group_max_size     # Número máximo de nodes (default: 4)
    min_size     = var.node_group_min_size     # Número mínimo de nodes (default: 2)
  }

  # Dependências explícitas para garantir ordem de criação
  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly
  ]
}

# Segundo grupo de nodes (usa instâncias t3.micro específicas)
resource "aws_eks_node_group" "node-2" {
  cluster_name    = aws_eks_cluster.cluster.name # Nome do cluster EKS
  node_group_name = "node-2"                     # Nome do grupo de nodes
  node_role_arn   = aws_iam_role.node.arn        # ARN da role IAM para os nodes
  subnet_ids      = aws_subnet.subnets[*].id     # Sub-redes onde os nodes serão criados
  instance_types  = ["t3.micro"]                 # Tipo de instância específico para este grupo

  # Configuração de auto-scaling
  scaling_config {
    desired_size = var.node_group_desired_size # Número desejado de nodes (default: 2)
    max_size     = var.node_group_max_size     # Número máximo de nodes (default: 4)
    min_size     = var.node_group_min_size     # Número mínimo de nodes (default: 2)
  }

  # Dependências explícitas para garantir ordem de criação
  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly
  ]
}

