# Aula 10 — Terraform Automatizado (GitOps) + CD Pipeline

[![CD Pipeline](https://github.com/CarinaDalpino/unifaat-devops-portfolio/actions/workflows/cd.yml/badge.svg)](https://github.com/CarinaDalpino/unifaat-devops-portfolio/actions/workflows/cd.yml)
[![Terraform Plan](https://github.com/CarinaDalpino/unifaat-devops-portfolio/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/CarinaDalpino/unifaat-devops-portfolio/actions/workflows/terraform-plan.yml)

Infraestrutura gerenciada via GitOps (plan no PR, apply no merge) + pipeline de Continuous Deployment (CI → build → push ECR → deploy Recreate na EC2 com health check).

**Aluno:** Carina Dal Pino — **RA:** 6325109

---

## Estrutura

Os workflows ficam na **raiz** do repositório (exigência do GitHub Actions). O código vive em `aula-10/`.

```
unifaat-devops-portfolio/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml    # plan automático em PRs (comenta no PR)
│       ├── terraform-apply.yml   # apply automático no merge para main
│       └── cd.yml                # CD: lint→test→build→push(ECR)→deploy(EC2)
└── aula-10/
    ├── terraform/                # IaC (backend S3, VPC, SG, EC2, ECR)
    │   ├── provider.tf
    │   ├── variables.tf
    │   ├── main.tf
    │   └── outputs.tf
    ├── technova-api/             # aplicação (build context do CD)
    │   ├── Dockerfile
    │   ├── server.js
    │   └── package.json
    ├── docs/
    │   └── runbook-rollback.md
    ├── gitops-cd-analise.md      # documentação e análise crítica
    ├── screenshots/              # evidências do TF
    └── README.md
```

---

## Fluxo GitOps (Terraform)

```
PR com mudança em aula-10/terraform/*.tf
   → terraform-plan.yml: init + validate + plan → comenta no PR
   → revisão humana → merge na main
   → terraform-apply.yml: apply -auto-approve
```

## Pipeline CD (aplicação)

```
push na main (aula-10/technova-api/**)
   → lint → test → build-push (Amazon ECR) → deploy (SSH Recreate) → health check
```

Estratégia de deploy: **Recreate** (stop → rm → pull → run). Registry: **Amazon ECR**.

---

## Pré-requisitos para executar (AWS Academy Learner Lab)

Este projeto depende de AWS real. Antes de rodar, com o Learner Lab **ativo**:

1. **Secrets no GitHub** (Settings → Secrets and variables → Actions):

   | Secret | Valor |
   |--------|-------|
   | `AWS_ACCESS_KEY_ID` | credencial de sessão do Lab |
   | `AWS_SECRET_ACCESS_KEY` | credencial de sessão do Lab |
   | `AWS_SESSION_TOKEN` | token de sessão do Lab (expira por sessão) |
   | `AWS_ACCOUNT_ID` | Account ID da conta do Lab |
   | `EC2_HOST` | IP público da EC2 (output `ec2_public_ip`) |
   | `EC2_USERNAME` | `ubuntu` |
   | `EC2_SSH_KEY` | conteúdo da chave privada `.pem` |

2. **Backend S3** existente (bucket `technova-tfstate-6325109` + tabela `technova-tflock`). Ajuste em `terraform/provider.tf` se os nomes forem outros.

3. **Provisionar a infra** (primeira vez, localmente ou via apply):
   ```bash
   cd aula-10/terraform
   terraform init
   terraform apply   # cria VPC, SG, EC2 (Docker+AWS CLI) e repositório ECR
   ```

> As credenciais do Lab **expiram por sessão** — reabra o Lab e atualize os 3 secrets AWS quando um workflow falhar com `ExpiredToken`.

---

## Como testar a aplicação localmente

```bash
cd aula-10/technova-api
npm ci
npm run lint
npm test
docker build -t technova-api:local .
docker run -d -p 3000:3000 --name technova technova-api:local
curl http://localhost:3000/health
docker stop technova && docker rm technova
```

---

## Rollback

Procedimento manual documentado em [`docs/runbook-rollback.md`](./docs/runbook-rollback.md).

## Análise e decisões

Documentação completa (GitOps, auth Lab vs OIDC, Recreate, CD vs Delivery, limitações) em [`gitops-cd-analise.md`](./gitops-cd-analise.md).

---

## Checklist de evidências (TF)

- [ ] Plan como comentário no PR — `screenshots/plan-pr-comment.png`
- [ ] Apply executado após merge — `screenshots/apply-success.png`
- [ ] Pipeline CD completo verde — `screenshots/cd-pipeline-green.png`
- [ ] Health check passando no log — `screenshots/health-check-pass.png`
