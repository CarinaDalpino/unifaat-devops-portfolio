# Aula 03 — Terraform + IAM na AWS

**Aluno:** Carina Gonçalves dos Santos Dalpino  
**RA:** 6325109

---

## Sobre o Projeto

Este projeto provisiona um modelo de segurança IAM completo para a equipe TechNova usando Terraform. Toda a infraestrutura é declarada como código, versionável e reproduzível — eliminando o problema de credenciais compartilhadas e acessos sem controle.

---

## Arquitetura IAM

```
Conta AWS TechNova
│
├── Groups
│   ├── technova-developers     → developer-s3-policy + cloudwatch-read-policy
│   ├── technova-devops         → devops-policy
│   └── technova-readonly       → ReadOnlyAccess (AWS managed)
│
├── Users
│   ├── technova-dev-joao       → grupo developers
│   ├── technova-dev-maria      → grupo developers
│   ├── technova-devops-carlos  → grupo devops
│   ├── technova-devops-ana     → grupo devops
│   └── technova-readonly-marcos→ grupo readonly
│
├── Custom Policies
│   ├── developer-s3-policy     → s3:Get/Put/Delete no bucket technova-*
│   ├── cloudwatch-read-policy  → logs e métricas somente leitura
│   └── devops-policy           → S3 completo + EC2 read + IAM roles
│
└── Service Role
    └── technova-ec2-s3-role    → assumido por EC2
        └── Instance Profile: technova-ec2-instance-profile
```

---

## Estrutura de Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `providers.tf` | Configuração do provider AWS e tags padrão |
| `variables.tf` | Variáveis de entrada (região, ambiente, lista de usuários) |
| `main.tf` | Users, groups e memberships IAM |
| `policies.tf` | 3 custom policies seguindo menor privilégio |
| `roles.tf` | Service role para EC2 + instance profile |
| `outputs.tf` | Valores exportados após o apply |
| `.gitignore` | Exclui `.tfstate`, `.terraform/` e segredos |

---

## Como Usar

### Pré-requisitos

- Terraform >= 1.0 instalado
- AWS CLI configurado com credenciais válidas
- Permissão `IAMFullAccess` na conta AWS

### Executar

```bash
# 1. Inicializar o Terraform (baixa o provider AWS)
terraform init

# 2. Visualizar o que será criado (sem aplicar)
terraform plan

# 3. Criar os recursos na AWS
terraform apply

# 4. Ao finalizar, destruir todos os recursos
terraform destroy
```

---

## Design de Segurança — Princípio do Menor Privilégio

Cada grupo recebe apenas as permissões mínimas necessárias para sua função:

| Grupo | O que pode fazer | O que NÃO pode fazer |
|-------|-----------------|----------------------|
| `developers` | Ler/escrever no S3 do projeto, ver logs | Criar/deletar usuários, acessar EC2 |
| `devops` | S3 completo, ver EC2, gerenciar roles | Criar usuários IAM, acessar RDS |
| `readonly` | Ver todos os recursos (read-only) | Criar, alterar ou deletar qualquer recurso |

### Por que usar Roles em vez de Access Keys para EC2?

| Access Keys | Roles (Service Role) |
|-------------|---------------------|
| Credenciais fixas no código | Credenciais temporárias automáticas |
| Se vazar, acesso permanente | Rotação automática a cada hora |
| Difícil de revogar | Revoga desanexando o role |
| Má prática de segurança | Recomendação oficial AWS |

---

## Reflexão sobre Menor Privilégio

O maior desafio ao aplicar o princípio do menor privilégio é encontrar o equilíbrio entre segurança e produtividade. Permissões muito restritas travam o trabalho da equipe; permissões amplas demais criam riscos. A solução adotada foi:

1. **Começar com zero** — nenhum usuário tem permissão por padrão
2. **Adicionar por grupo** — permissões são aplicadas aos grupos, não a usuários individuais
3. **Escopo por recurso** — as policies restringem acesso apenas aos buckets `technova-*`, não a todos os buckets da conta
4. **Separar funções** — developers não precisam ver EC2, devops não precisam criar usuários IAM

Essa abordagem garante que um comprometimento de uma credencial individual tenha impacto limitado — o atacante teria acesso apenas ao escopo daquele grupo, não à conta inteira.
