# TechNova - Biblioteca de Modulos Terraform (Aula 06)

**Aluno:** Carina Goncalves dos Santos Dalpino
**RA:** 6325109
**Disciplina:** DevOps - Centro Universitario UniFAAT
**Professor:** Alexandre Tavares
**Semestre:** 2026-2

---

## Visao Geral

Biblioteca de modulos Terraform reutilizaveis para provisionar a infraestrutura da TechNova. Com os mesmos modulos, provisionamos ambientes completos (dev e staging) apenas variando os valores das variaveis. A biblioteca contem 4 modulos: **VPC**, **Security Group**, **EC2** e **RDS**.

---

## Arquitetura - Dependencias entre Modulos

```
                    +-------------------+
                    |    modulo VPC     |
                    | (for_each subnets)|
                    +---------+---------+
                              |
              vpc_id          |  public_subnet_ids / private_subnet_ids
        +---------------------+---------------------+
        |                     |                     |
        v                     v                     v
+---------------+   +-----------------+   +------------------+
| Security Group|   |   modulo EC2    |   |   modulo RDS     |
|  (API + RDS)  |   | (subnet publica)|   |(subnets privadas)|
+-------+-------+   +--------+--------+   +--------+---------+
        |                    ^                     ^
        |  sg_id (API)       |                     |
        +--------------------+                     |
        |  sg_id (RDS)                             |
        +------------------------------------------+
```

**Fluxo de composicao:**
- `module.vpc.vpc_id` -> alimenta os Security Groups (API e RDS)
- `module.vpc.public_subnet_ids[0]` -> alimenta o modulo EC2
- `module.vpc.private_subnet_ids` -> alimenta o modulo RDS (DB Subnet Group)
- `module.api_sg.sg_id` -> alimenta o modulo EC2
- `module.rds_sg.sg_id` -> alimenta o modulo RDS

---

## Estrutura do Projeto

```
aula-06/
├── README.md
├── environments/
│   ├── dev/       (main.tf, variables.tf, outputs.tf, providers.tf, terraform.tfvars)
│   └── staging/   (main.tf, variables.tf, outputs.tf, providers.tf, terraform.tfvars)
└── modules/
    ├── vpc/               (VPC + subnets com for_each + IGW + route table)
    ├── security-group/    (SG generico com regras dinamicas)
    ├── ec2/               (instancia EC2 reutilizavel)
    └── rds/               (RDS PostgreSQL + DB Subnet Group)
```

---

## Modulos Disponiveis

### Modulo VPC

**Descricao:** Cria VPC completa com subnets dinamicas usando `for_each`, Internet Gateway e route table publica. Diferencia subnets publicas e privadas pelo campo `type` do mapa.

**Inputs:**
| Nome | Tipo | Obrigatorio | Descricao |
|------|------|-------------|-----------|
| vpc_cidr | string | Sim | CIDR block da VPC |
| project_name | string | Sim | Nome do projeto |
| environment | string | Sim | Ambiente (dev, staging, prod) |
| subnets | map(object) | Sim | Mapa de subnets com cidr, az e type |

**Outputs:**
| Nome | Descricao |
|------|-----------|
| vpc_id | ID da VPC criada |
| vpc_cidr | CIDR da VPC |
| subnet_ids | Mapa de todos os subnet IDs |
| public_subnet_ids | Lista de IDs das subnets publicas |
| private_subnet_ids | Lista de IDs das subnets privadas |

**Exemplo de uso:**
```hcl
module "vpc" {
  source       = "../../modules/vpc"
  vpc_cidr     = "10.0.0.0/16"
  project_name = "technova"
  environment  = "dev"
  subnets = {
    "public-1"  = { cidr = "10.0.1.0/24", az = "us-east-1a", type = "public" }
    "private-1" = { cidr = "10.0.3.0/24", az = "us-east-1a", type = "private" }
  }
}
```

---

### Modulo Security Group

**Descricao:** Security Group generico que funciona para qualquer finalidade (API, RDS, bastion). Recebe regras de ingress como lista de objetos e tem egress padrao (all outbound).

**Inputs:**
| Nome | Tipo | Obrigatorio | Descricao |
|------|------|-------------|-----------|
| name | string | Sim | Nome do Security Group |
| vpc_id | string | Sim | ID da VPC |
| ingress_rules | list(object) | Nao | Regras de entrada (default: []) |
| egress_rules | list(object) | Nao | Regras de saida (default: all outbound) |
| environment | string | Sim | Ambiente |
| project_name | string | Sim | Nome do projeto |

**Outputs:**
| Nome | Descricao |
|------|-----------|
| sg_id | ID do Security Group criado |
| sg_name | Nome do Security Group |

**Exemplo de uso:**
```hcl
module "api_sg" {
  source       = "../../modules/security-group"
  name         = "technova-dev-api-sg"
  vpc_id       = module.vpc.vpc_id
  environment  = "dev"
  project_name = "technova"
  ingress_rules = [
    { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP" }
  ]
}
```

---

### Modulo EC2

**Descricao:** Cria uma instancia EC2 reutilizavel com AMI, tipo, subnet e Security Groups configuraveis. Aceita user_data opcional.

**Inputs:**
| Nome | Tipo | Obrigatorio | Descricao |
|------|------|-------------|-----------|
| instance_name | string | Sim | Nome da instancia |
| instance_type | string | Nao | Tipo (default: t2.micro) |
| ami_id | string | Sim | AMI ID |
| subnet_id | string | Sim | Subnet ID |
| security_group_ids | list(string) | Sim | Lista de SG IDs |
| key_name | string | Sim | Nome do key pair |
| user_data | string | Nao | Script user_data (default: "") |
| environment | string | Sim | Ambiente |
| project_name | string | Sim | Nome do projeto |

**Outputs:**
| Nome | Descricao |
|------|-----------|
| instance_id | ID da instancia EC2 |
| public_ip | IP publico da instancia |
| private_ip | IP privado da instancia |

**Exemplo de uso:**
```hcl
module "api_server" {
  source             = "../../modules/ec2"
  instance_name      = "technova-dev-api"
  ami_id             = data.aws_ami.amazon_linux.id
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.api_sg.sg_id]
  key_name           = "technova-key"
  environment        = "dev"
  project_name       = "technova"
}
```

---

### Modulo RDS

**Descricao:** Cria um DB Subnet Group com subnets privadas e uma instancia RDS PostgreSQL (db.t3.micro). Configuracoes sensatas para desenvolvimento (skip_final_snapshot, storage encriptado, sem acesso publico).

**Inputs:**
| Nome | Tipo | Obrigatorio | Descricao |
|------|------|-------------|-----------|
| db_name | string | Sim | Nome do database |
| db_username | string | Sim | Usuario master |
| db_password | string (sensitive) | Sim | Senha master |
| subnet_ids | list(string) | Sim | Subnet IDs para o DB Subnet Group |
| security_group_ids | list(string) | Sim | SG IDs para o RDS |
| instance_class | string | Nao | Classe da instancia (default: db.t3.micro) |
| environment | string | Sim | Ambiente |
| project_name | string | Sim | Nome do projeto |

**Outputs:**
| Nome | Descricao |
|------|-----------|
| db_endpoint | Endpoint de conexao do RDS |
| db_name | Nome do banco de dados |
| db_port | Porta do RDS (5432) |

**Exemplo de uso:**
```hcl
module "database" {
  source             = "../../modules/rds"
  db_name            = "technova_dev"
  db_username        = "technova_admin"
  db_password        = var.db_password
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.rds_sg.sg_id]
  environment        = "dev"
  project_name       = "technova"
}
```

---

## Dois Ambientes com os Mesmos Modulos

| Aspecto | Dev | Staging |
|---------|-----|---------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| Subnets Publicas | 10.0.1.0/24, 10.0.2.0/24 | 10.1.1.0/24, 10.1.2.0/24 |
| Subnets Privadas | 10.0.3.0/24, 10.0.4.0/24 | 10.1.3.0/24, 10.1.4.0/24 |
| EC2 | t2.micro | t2.micro |
| RDS | db.t3.micro | db.t3.micro |
| DB Name | technova_dev | technova_staging |
| Naming Pattern | technova-dev-* | technova-staging-* |

A unica diferenca entre os ambientes esta no arquivo `terraform.tfvars`. Os arquivos `main.tf`, `providers.tf`, `variables.tf` e `outputs.tf` sao identicos, pois ambos chamam os mesmos modulos.

---

## Pre-requisitos

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configurado (AWS Academy Learner Lab)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- Key Pair `technova-key` criado na conta AWS (para o EC2)

---

## Como Usar

### Provisionar o ambiente DEV

```bash
cd environments/dev
terraform init
terraform validate
terraform plan
terraform apply    # opcional - cria recursos reais na AWS
```

### Provisionar o ambiente STAGING

```bash
cd environments/staging
terraform init
terraform validate
terraform plan
terraform apply    # opcional
```

### Destruir (sempre apos testar)

```bash
terraform destroy
```

> Nota: dois ambientes ao mesmo tempo consomem o dobro de recursos do Learner Lab. Teste um de cada vez e sempre execute `terraform destroy` ao final.