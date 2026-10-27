# Análise — Terraform GitOps e CD Pipelines

**Aluno:** Carina Dal Pino
**RA:** 6325109
**Aula:** 10 — Terraform Automatizado e CD Pipelines

---

## 1. Fluxo GitOps: por que plan no PR e apply no merge

GitOps trata o **repositório Git como a única fonte da verdade** da infraestrutura. Nenhuma pessoa roda `terraform apply` na própria máquina — toda mudança passa por Pull Request.

| Etapa | O que acontece | Por quê |
|-------|----------------|---------|
| Abrir PR com mudança em `.tf` | `terraform-plan.yml` roda `init` + `validate` + `plan` e posta o resultado como comentário | O revisor vê **exatamente** o que vai ser criado/alterado/destruído antes de aprovar |
| Revisão do PR | O time lê o plan no comentário | "Vai destruir um recurso? O custo muda? É intencional?" |
| Merge na `main` | `terraform-apply.yml` roda `apply -auto-approve` | O merge **é** a aprovação humana; o `-auto-approve` é seguro porque o plan já foi revisado |

**Benefícios:** auditoria total (quem/quando/o quê no histórico do Git), revisão formal (não é "ok" no chat), nenhuma credencial na máquina de ninguém, e state remoto compartilhado evita execuções concorrentes.

---

## 2. Autenticação no Learner Lab (credenciais de sessão) vs OIDC em produção

### O que foi implementado (Learner Lab)

O GitHub Actions autentica na AWS com as **3 credenciais temporárias da sessão** do Learner Lab, guardadas como GitHub Secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` (obrigatório — credencial de sessão sempre tem token)

Usadas pela action `aws-actions/configure-aws-credentials@v4`. Elas **expiram quando a sessão do Lab encerra**, então precisam ser atualizadas nos secrets a cada reabertura do Lab (senão os workflows falham com `ExpiredToken`).

### Por que OIDC seria o ideal em produção

O padrão recomendado pela AWS é **OIDC (OpenID Connect)**: o GitHub Actions pede um token temporário à AWS, que assume uma **role IAM** — sem armazenar chave nenhuma. Vantagens:

- Nenhuma credencial de longa duração guardada como secret (nada pra vazar)
- Credenciais duram só o tempo do job
- Escopo restrito por repositório/branch via a trust policy da role

### Por que não dá pra usar OIDC no Lab

O OIDC exige criar um **IAM OIDC Identity Provider** e uma **role IAM** — e o **AWS Academy Learner Lab não permite criar provider OIDC nem roles IAM**. Por isso, no laboratório, o caminho real é as credenciais de sessão como secrets. Não há `oidc.tf` nesta entrega porque o Lab não permite esses recursos.

---

## 3. Estratégia de Deploy: Recreate

A estratégia implementada no `cd.yml` (job `deploy`) é **Recreate**:

```
login ECR → docker pull → docker stop → docker rm → docker run
```

| Prós | Contras |
|------|---------|
| Simplicidade total (poucos comandos) | **Downtime** entre o stop e o start |
| Sem conflito de portas (um container por vez) | Sem rollback automático se a nova versão falhar |
| Estado limpo (sem versão antiga coexistindo) | Não serve para SLA de alta disponibilidade |
| Não precisa de load balancer | — |

**Quando usar:** aplicações internas, ambientes de staging/dev, MVPs e startups que toleram alguns segundos de downtime. Para a TechNova (startup, 1 servidor) é adequado por enquanto. Com crescimento e SLA mais rígido, evoluir para Blue-Green (aula 11) ou Canary (aula 12).

---

## 4. Continuous Delivery vs Continuous Deployment

| | Continuous Delivery | Continuous Deployment |
|---|---------------------|----------------------|
| Deploy em produção | Requer **aprovação manual** (botão/review) | **Automático** após os checks passarem |
| Intervenção humana | Sim, no passo final | Nenhuma entre commit e produção |
| Quando usar | Compliance, releases planejados | SaaS, startups, iteração rápida |

**Nesta aula** implementamos **Continuous Deployment**: merge na `main` → pipeline roda lint/test/build/push e **deploya sozinho** na EC2. Para transformar em Continuous *Delivery*, bastaria adicionar "Required reviewers" no GitHub Environment `production` (o `cd.yml` já usa `environment: production`, então é só ativar a proteção com aprovação).

---

## 5. Procedimento de Rollback (manual nesta etapa)

Rollback = voltar para uma imagem anterior já publicada no ECR. O pré-requisito é ter **imagens versionadas por SHA** (o `cd.yml` gera a tag `sha-<commit>` em todo push).

Passos resumidos (detalhado em [`docs/runbook-rollback.md`](./docs/runbook-rollback.md)):

1. Identificar o SHA da última versão estável (console do ECR ou `aws ecr list-images`)
2. SSH na EC2
3. **Login no ECR antes do pull** (token temporário):
   ```bash
   REGISTRY=<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
   aws ecr get-login-password --region us-east-1 \
     | docker login --username AWS --password-stdin "$REGISTRY"
   ```
4. `docker stop` + `docker rm` + `docker run` com a tag `sha-<commit_bom>`
5. Verificar `/health` e comunicar o time

> O login no ECR **antes** do pull é essencial — sem ele o pull falha com `denied`.

---

## 6. Limitações Identificadas e Melhorias Futuras

- **Downtime (Recreate):** há indisponibilidade entre o stop e o start. Melhoria: Blue-Green (aula 11) para zero downtime.
- **Rollback manual:** depende de uma pessoa executar SSH. Melhoria: rollback automático quando o health check falhar.
- **Credenciais de sessão expiram:** precisam ser atualizadas a cada sessão do Lab. Melhoria (fora do Lab): OIDC + role IAM, sem chaves.
- **SSH com `0.0.0.0/0` na porta 22:** aberto para qualquer IP porque os runners do GitHub têm IPs variáveis. Melhoria: restringir aos [ranges do GitHub](https://api.github.com/meta) ou usar Bastion/VPN.
- **Deploy por `latest`:** o container sobe com a tag `latest`; o ideal para rastreabilidade total seria subir pela tag `sha-<commit>` (a imagem por SHA já é publicada, então é uma mudança pequena no `docker run`).
- **Um único servidor:** sem redundância. Melhoria: múltiplas instâncias atrás de um load balancer.
