# ============================================================================
# VPC (Virtual Private Cloud)
# ============================================================================
# Cria uma rede virtual isolada na AWS onde todos os recursos serão implantados
resource "aws_vpc" "new-vpc" {
  cidr_block = "10.0.0.0/16" # Bloco de IP principal: 65.536 endereços IP (10.0.0.0 a 10.0.255.255)

  tags = {
    Name = "${var.prefix}-vpc" # Nome da VPC usando prefixo da variável
  }
}

# ============================================================================
# DATA SOURCE - Availability Zones
# ============================================================================
# Obtém informações sobre as zonas de disponibilidade disponíveis na região
data "aws_availability_zones" "available" {}

# Output para exibir as zonas disponíveis
output "available_zones" {
  value = data.aws_availability_zones.available.names # Lista de zonas (ex: us-east-1a, us-east-1b)
}

# ============================================================================
# SUBNETS - Sub-redes Públicas
# ============================================================================
# Cria 2 sub-redes públicas em diferentes zonas de disponibilidade
resource "aws_subnet" "subnets" {
  count                   = 2                                                        # Número de sub-redes a serem criadas
  availability_zone       = data.aws_availability_zones.available.names[count.index] # Zona de disponibilidade (AZ1, AZ2)
  vpc_id                  = aws_vpc.new-vpc.id                                       # ID da VPC onde a subnet será criada
  cidr_block              = "10.0.${count.index + 1}.0/24"                           # Bloco IP: 254 endereços por subnet
  map_public_ip_on_launch = true                                                     # Instâncias EC2 recebem IP público automaticamente

  tags = {
    Name = "${var.prefix}-subnet-${count.index + 1}" # Nome da subnet (prefix-subnet-1, prefix-subnet-2)
  }
}

# ============================================================================
# INTERNET GATEWAY
# ============================================================================
# Permite comunicação entre a VPC e a internet
# Essencial para que as sub-redes públicas acessem a internet
resource "aws_internet_gateway" "new-igw" {
  vpc_id = aws_vpc.new-vpc.id # ID da VPC onde o gateway será anexado

  tags = {
    Name = "${var.prefix}-igw" # Nome do Internet Gateway
  }
}

# ============================================================================
# ROUTE TABLE - Tabela de Roteamento
# ============================================================================
# Define como o tráfego de rede é direcionado dentro da VPC
resource "aws_route_table" "new-rtb" {
  vpc_id = aws_vpc.new-vpc.id # ID da VPC onde a tabela será criada

  # Rota para tráfego de saída para internet
  route {
    cidr_block = "0.0.0.0/0"                     # Todo tráfego destinado à internet
    gateway_id = aws_internet_gateway.new-igw.id # Direciona para o Internet Gateway
  }

  tags = {
    Name = "${var.prefix}-rtb" # Nome da tabela de roteamento
  }
}

# ============================================================================
# ROUTE TABLE ASSOCIATION - Associação da Tabela de Roteamento
# ============================================================================
# Associa a tabela de roteamento às sub-redes para torná-las públicas
resource "aws_route_table_association" "new-rtb-association" {
  count          = 2                                    # Número de associações (uma para cada subnet)
  route_table_id = aws_route_table.new-rtb.id           # ID da tabela de roteamento
  subnet_id      = aws_subnet.subnets.*.id[count.index] # ID da subnet (usando splat operator)
}

# ============================================================================
# SUBNETS COMENTADAS (Alternativa Manual)
# ============================================================================
# Abaixo está a versão manual comentada das subnets acima
# resource "aws_subnet" "new-subnet-1" {
#   availability_zone = "us-east-1a"  # Zona de disponibilidade fixa
#   vpc_id            = aws_vpc.new-vpc.id  # Referência à VPC
#   cidr_block        = "10.0.1.0/24"  # 254 IPs (10.0.1.1 a 10.0.1.254)
#
#   tags = {
#     Name = "${var.prefix}-subnet-1"  # Nome da subnet
#   }
# }
#
# resource "aws_subnet" "new-subnet-2" {
#   availability_zone = "us-east-1b"  # Segunda zona de disponibilidade
#   vpc_id            = aws_vpc.new-vpc.id  # Referência à VPC
#   cidr_block        = "10.0.2.0/24"  # 254 IPs (10.0.2.1 a 10.0.2.254)
#
#   tags = {
#     Name = "${var.prefix}-subnet-2"  # Nome da subnet
#   }
# }
