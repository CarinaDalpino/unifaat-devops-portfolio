# Infraestrutura TechNova — Aula 04: VPC + EC2 Multi-AZ

**Aluno:** Carina Gonçalves dos Santos Dalpino  
**RA:** 6325109  
**Disciplina:** DevOps — Centro Universitário UniFAAT  
**Professor:** Alexandre Tavares  
**Semestre:** 2026-2  

---

## Diagrama da Arquitetura

```
                          Internet
                              │
                    ┌─────────▼─────────┐
                    │  Internet Gateway  │
                    └─────────┬─────────┘
                              │
              ┌───────────────▼───────────────┐
              │         VPC 10.0.0.0/16        │
              │                               │
              │  ┌────────────────────────┐   │
              │  │     us-east-1a         │   │
              │  │  ┌──────────────────┐  │   │
              │  │  │  Public Subnet 1 │  │   │
              │  │  │  10.0.1.0/24     │  │   │
              │  │  │  [EC2 - API]     │  │   │
              │  │  └──────────────────┘  │   │
              │  │  ┌──────────────────┐  │   │
              │  │  │  Private Subnet 1│  │   │
              │  │  │  10.0.2.0/24     │  │   │
              │  │  │  [futuro: RDS]   │  │   │
              │  │  └──────────────────┘  │   │
              │  └────────────────────────┘   │
              │                               │
              │  ┌────────────────────────┐   │
              │  │     us-east-1b         │   │
              │  │  ┌──────────────────┐  │   │
              │  │  │  Public Subnet 2 │  │   │
              │  │  │  10.0.3.0/24     │  │   │
              │  │  │  [futuro: ALB]   │  │   │
              │  │  └──────────────────┘  │   │
              │  │  ┌──────────────────┐  │   │
              │  │  │  Private Subnet 2│  │   │
              │  │  │  10.0.4.0/24     │  │   │
              │  │  │  [futuro: RDS]   │  │   │
              │  │  └──────────────────┘  │   │
              │  └────────────────────────┘   │
              └───────────────────────────────┘
```

---

## Recursos Criados

| Recurso | Nome | Função |
|---------|------|--------|
| VPC | technova-vpc | Rede isolada 10.0.0.0/16 |
| Subnet Pública 1 | technova-public-subnet-1 | us-east-1a — EC2 da API |
| Subnet Pública 2 | technova-public-subnet-2 | us-east-1b — futura redundância |
| Subnet Privada 1 | technova-private-subnet-1 | us-east-1a — futura RDS |
| Subnet Privada 2 | technova-private-subnet-2 | us-east-1b — futura RDS |
| Internet Gateway | technova-igw | Conecta VPC à internet |
| Route Table | technova-public-rt | Roteia tráfego público → IGW |
| Security Group | technova-api-sg | Portas 22 e 3000 abertas |
| Security Group | technova-db-sg | Porta 5432 apenas da VPC |
| IAM Role | technova-ec2-role | Permissões S3ReadOnly para EC2 |
| Instance Profile | technova-ec2-profile | Vincula role ao EC2 |
| Key Pair | technova-key | Acesso SSH ao EC2 |
| EC2 | technova-api-ec2 | t3.micro com API Node.js |

---

## Pré-requisitos

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configurado (`aws configure`)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- Conta AWS com Free Tier ativo
- Credenciais com permissões de EC2, VPC e IAM

---

## Como Usar

### 1. Inicializar o Terraform

```bash
cd aula-04/
terraform init
```

### 2. Planejar a infraestrutura

```bash
terraform plan
# Salvar evidência:
terraform plan > evidencia-plan.txt
```

### 3. Aplicar

```bash
terraform apply
# Digite "yes" quando solicitado
```

### 4. Testar a API

Aguarde ~2 minutos para o User Data finalizar e execute:

```bash
# Pegar o IP do output
terraform output ec2_public_ip

# Testar a API
curl http://<IP_PUBLICO>:3000
curl http://<IP_PUBLICO>:3000/health

# Salvar evidência:
curl http://<IP_PUBLICO>:3000 > evidencia-api.json
curl http://<IP_PUBLICO>:3000/health >> evidencia-api.json
```

### 5. Conectar via SSH

```bash
# O comando exato vem do output:
terraform output ssh_command

# Ou manualmente:
ssh -i technova-key.pem ec2-user@<IP_PUBLICO>
```

### 6. Destruir após evidências

> ⚠️ Sempre destruir para evitar custos!

```bash
terraform destroy
# Digite "yes" quando solicitado
```

---

## Decisões Técnicas

**Por que t3.micro em vez de t2.micro?**  
O requisito original especifica `t2.micro`, mas na conta AWS utilizada (us-east-1), o `t2.micro` não estava disponível como Free Tier elegível. O `t3.micro` é a geração mais recente, também elegível ao Free Tier na maioria das contas em us-east-1, e oferece melhor performance com o mesmo custo zero. Ambos são Free Tier — verificar elegibilidade em: https://aws.amazon.com/free/. Nas próximas entregas, usar `t2.micro` quando disponível conforme requisito.

**Por que SSH aberto para 0.0.0.0/0?**  
Para este laboratório, o SSH está aberto para qualquer IP via variável `allowed_ssh_cidr` (default `0.0.0.0/0`). Em produção, o correto seria:
- Restringir a um IP específico: `allowed_ssh_cidr = "seu-ip/32"`
- Ou usar um Bastion Host (jump server) em subnet pública e remover SSH direto ao EC2
- Ou substituir SSH por AWS Systems Manager Session Manager (sem porta aberta)

**Por que Multi-AZ?**  
Distribuir subnets em múltiplas Availability Zones garante alta disponibilidade. Se uma AZ falhar, a outra continua operando. Essa é a base para adicionar um Load Balancer no futuro.

**Por que separar subnets públicas e privadas?**  
Seguindo o princípio do menor privilégio em rede: a API precisa ser acessível da internet (subnet pública), mas o banco de dados nunca deve ser exposto diretamente (subnet privada, acessível apenas pela VPC interna).

**Por que as subnets privadas não têm NAT Gateway?**  
O NAT Gateway não foi incluído nesta aula pois o requisito especifica apenas "subnets privadas usam a Route Table padrão (sem rota para internet)". Isso é intencional para o escopo da aula-04. Na aula-05 (RDS), será necessário adicionar NAT Gateway para que recursos em subnets privadas (como RDS) possam baixar patches e atualizações sem expor uma rota de entrada da internet.

**Por que IAM Role em vez de credenciais na instância?**  
IAM Roles são a forma segura de conceder permissões ao EC2. Credenciais hardcoded são uma vulnerabilidade crítica — roles rotacionam automaticamente e não precisam de gestão manual.

**Por que systemd para a API?**  
O serviço systemd garante que a API inicie automaticamente após reboots e se reinicie em caso de falhas, sem intervenção manual.

---

## ⚠️ Aviso de Custos

> **SEMPRE execute `terraform destroy` após capturar as evidências!**

Recursos que geram custo se não destruídos:

| Recurso | Custo fora do Free Tier |
|---------|------------------------|
| EC2 t3.micro | ~$0.0104/hora após 750h/mês |
| Key Pair | Gratuito |
| VPC, Subnets, IGW, Route Tables, Security Groups | Sempre gratuitos |
| IAM Role / Instance Profile | Sempre gratuitos |

O Free Tier cobre 750 horas/mês de EC2 — mas se você tiver outras instâncias rodando, as horas somam. **Destrua sempre após o lab.**
