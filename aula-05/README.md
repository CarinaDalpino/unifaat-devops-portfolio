# Infraestrutura TechNova — Aula 05: RDS + Remote State

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
         ┌────────────────────▼────────────────────────┐
         │              VPC 10.0.0.0/16                 │
         │                                              │
         │   ┌──────────────────────────────────────┐  │
         │   │         us-east-1a                   │  │
         │   │  ┌─────────────────┐                 │  │
         │   │  │  Public Subnet  │                 │  │
         │   │  │  10.0.1.0/24   │                 │  │
         │   │  │  [EC2 t2.micro] │                 │  │
         │   │  │  SG: 22, 3000  │                 │  │
         │   │  └─────────────────┘                 │  │
         │   │  ┌─────────────────┐                 │  │
         │   │  │ Private Subnet 1│                 │  │
         │   │  │  10.0.2.0/24   │                 │  │
         │   │  │  [RDS primário] │                 │  │
         │   │  │  SG: 5432 EC2  │                 │  │
         │   │  └─────────────────┘                 │  │
         │   └──────────────────────────────────────┘  │
         │                                              │
         │   ┌──────────────────────────────────────┐  │
         │   │         us-east-1b                   │  │
         │   │  ┌─────────────────┐                 │  │
         │   │  │ Private Subnet 2│                 │  │
         │   │  │  10.0.4.0/24   │                 │  │
         │   │  │  [DB Subnet Grp]│                 │  │
         │   │  └─────────────────┘                 │  │
         │   └──────────────────────────────────────┘  │
         └──────────────────────────────────────────────┘

         ┌───────────────────────────────────────────┐
         │         Remote State (S3 + DynamoDB)      │
         │  S3: technova-terraform-state-XXXXXXXX    │
         │  DynamoDB: technova-terraform-locks        │
         └───────────────────────────────────────────┘
```

---

## Recursos Criados

### Projeto Principal (`aula-05/`)

| Recurso | Nome | Função |
|---------|------|--------|
| VPC | technova-vpc | Rede isolada 10.0.0.0/16 |
| Subnet Pública | technova-public-subnet | us-east-1a — EC2 da API |
| Subnet Privada 1 | technova-private-subnet-1 | us-east-1a — RDS primário |
| Subnet Privada 2 | technova-private-subnet-2 | us-east-1b — DB Subnet Group |
| Internet Gateway | technova-igw | Conecta VPC à internet |
| Route Table | technova-public-rt | Roteia tráfego público → IGW |
| Security Group EC2 | technova-ec2-sg | Portas 22 e 3000 |
| Security Group RDS | technova-rds-sg | Porta 5432 apenas do EC2 SG |
| DB Subnet Group | technova-db-subnet-group | Agrupa subnets privadas para RDS |
| RDS PostgreSQL | technova-db | db.t3.micro, PostgreSQL 15 |
| Key Pair | technova-key | Acesso SSH ao EC2 |
| EC2 | technova-api-ec2 | t2.micro com API Node.js + psql client |

### Backend (`aula-05/backend/`)

| Recurso | Nome | Função |
|---------|------|--------|
| S3 Bucket | technova-terraform-state-XXXX | Armazena terraform.tfstate |
| DynamoDB Table | technova-terraform-locks | Locking para evitar conflitos |

---

## Pré-requisitos

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configurado
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- Acesso ao AWS Academy Learner Lab
- Credenciais AWS ativas (`aws sts get-caller-identity`)

---

## Como Usar

### Passo 1 — Criar a infraestrutura de backend (S3 + DynamoDB)

```bash
cd aula-05/backend/
terraform init
terraform plan
terraform apply
# Anote os outputs: s3_bucket_name e dynamodb_table_name
```

### Passo 2 — Configurar o backend no projeto principal

Edite `aula-05/providers.tf` e descomente o bloco `backend "s3"`, substituindo com os valores do passo anterior:

```hcl
backend "s3" {
  bucket         = "technova-terraform-state-XXXXXXXX"
  key            = "aula-05/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "technova-terraform-locks"
}
```

### Passo 3 — Criar o arquivo `terraform.tfvars`

```bash
cd aula-05/
cat > terraform.tfvars << EOF
aws_region  = "us-east-1"
db_password = "TechNova2026Segura!"
EOF
```

> ⚠️ O arquivo `terraform.tfvars` está no `.gitignore` — nunca versionar (contém senha!)

### Passo 4 — Inicializar e aplicar

```bash
terraform init
terraform plan
terraform apply
# Digite "yes" quando solicitado
# O RDS leva 5-10 minutos — isso é normal
```

### Passo 5 — Testar a API

```bash
export EC2_IP=$(terraform output -raw ec2_public_ip)
curl http://$EC2_IP:3000
curl http://$EC2_IP:3000/health
curl http://$EC2_IP:3000/orders
```

### Passo 6 — Conectar via SSH e testar RDS

```bash
# Conectar ao EC2
ssh -i technova-key.pem ec2-user@$EC2_IP

# Dentro do EC2: conectar ao RDS
export RDS_HOST=$(terraform output -raw rds_address)
psql -h $RDS_HOST -U technova_admin -d technova -p 5432
# Senha: TechNova2026Segura!

# Criar tabela e inserir dados
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    product VARCHAR(100),
    quantity INTEGER,
    total DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO orders (customer_name, product, quantity, total) VALUES
    ('Maria Silva', 'Laptop TechNova Pro', 1, 4599.90),
    ('João Santos', 'Monitor 27"', 2, 2398.00),
    ('Ana Costa', 'Teclado Mecânico', 3, 897.00);

SELECT * FROM orders;
\q
```

### Passo 7 — Verificar o state no S3

```bash
aws s3 ls s3://SEU-BUCKET/aula-05/
```

### Passo 8 — Destruir após evidências

```bash
# 1. Destruir infraestrutura principal
cd aula-05/
terraform destroy

# 2. Esvaziar bucket S3 (inclui versões)
BUCKET="technova-terraform-state-XXXXXXXX"
aws s3api list-object-versions \
  --bucket $BUCKET \
  --query 'Versions[].{Key:Key,VersionId:VersionId}' \
  --output text | while read key version; do
    aws s3api delete-object --bucket $BUCKET --key "$key" --version-id "$version"
done

# 3. Destruir backend
cd aula-05/backend/
terraform destroy
```

---

## Decisões Técnicas

**Por que RDS em vez de PostgreSQL no EC2?**
O RDS gerencia patches, backups automáticos, monitoramento e failover. Para a TechNova (equipe pequena, sem DBA dedicado), o custo operacional menor justifica o uso de serviço gerenciado. PostgreSQL no EC2 seria adequado apenas se precisássemos de controle total sobre o sistema operacional do banco.

**Por que 2 subnets privadas em AZs diferentes para o RDS?**
A AWS exige que o DB Subnet Group contenha subnets em pelo menos 2 Availability Zones — mesmo com `multi_az = false`. Isso prepara a infraestrutura para habilitar Multi-AZ no futuro (standby em outra AZ) sem necessidade de recriar o grupo.

**Por que o Security Group do RDS referencia o SG do EC2 (e não o CIDR da VPC)?**
Referenciar o Security Group do EC2 como origem da porta 5432 é mais restritivo do que abrir para todo o CIDR da VPC (10.0.0.0/16). Apenas instâncias com o Security Group específico do EC2 conseguem conectar ao banco — princípio do menor privilégio aplicado em rede.

**Por que Remote State com S3 + DynamoDB?**
O `terraform.tfstate` contém senhas e mapeamento completo da infraestrutura. Armazená-lo localmente cria um ponto único de falha (laptop roubado/formatado = controle perdido) e impossibilita colaboração em equipe. O S3 centraliza o state com versionamento e encriptação; o DynamoDB previne corrupção por writes simultâneos via locking.

**Por que `skip_final_snapshot = true`?**
Adequado para laboratório. Em produção, sempre usar `skip_final_snapshot = false` para ter um snapshot do banco antes de qualquer destruição.

---

## ⚠️ Aviso de Custos

> **SEMPRE execute `terraform destroy` após capturar as evidências!**

| Recurso | Observação |
|---------|-----------|
| EC2 t2.micro | Free Tier: 750h/mês por 12 meses |
| RDS db.t3.micro | Free Tier: 750h/mês por 12 meses |
| RDS Storage 20 GB | Free Tier: 20 GB por 12 meses |
| S3 (state ~100 KB) | Free Tier: 5 GB por 12 meses |
| DynamoDB (lock table) | Sempre gratuito (25 GB) |
| VPC, Subnets, IGW | Sempre gratuitos |
| Multi-AZ RDS | ⚠️ NÃO usar — dobra o custo |
| NAT Gateway | ⚠️ NÃO usar — ~$32/mês |
