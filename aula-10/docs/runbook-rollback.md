# Runbook: Rollback de Deploy — TechNova API

## Quando usar

- Deploy causou erros na aplicação
- Health check passa, mas a funcionalidade está quebrada
- Bug crítico detectado após o deploy

## Pré-requisito

Imagens versionadas por SHA no Amazon ECR. O pipeline `cd.yml` publica a tag
`sha-<commit>` em todo push para `main`, então sempre há uma versão anterior
para voltar.

## Procedimento

### 1. Identificar o SHA da última versão estável

No console do Amazon ECR (Elastic Container Registry → Repositories → `technova-api`),
veja as tags e datas de push. Ou via CLI:

```bash
aws ecr list-images --repository-name technova-api --region us-east-1
git log --oneline -5   # mapear o SHA do commit estável
```

### 2. Conectar na EC2

```bash
ssh ubuntu@<EC2_HOST>
```

### 3. Login no ECR e troca da imagem (Recreate)

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"

# Login no ECR ANTES do pull (token temporário)
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin "$REGISTRY"

# Parar e remover o container atual
docker stop technova-api && docker rm technova-api

# Subir a versão anterior (substituir pelo SHA estável)
docker pull "$REGISTRY/technova-api:sha-COMMIT_BOM"
docker run -d --name technova-api \
  -p 3000:3000 \
  --restart unless-stopped \
  "$REGISTRY/technova-api:sha-COMMIT_BOM"
```

### 4. Verificar

```bash
curl http://localhost:3000/health   # deve retornar status ok
```

### 5. Comunicar

Avisar o time (Slack/Discord) sobre o rollback, o SHA restaurado e o motivo.

## Observações

- O login no ECR **antes** do `docker pull` é obrigatório — sem ele o pull falha com `denied`.
- Se as credenciais do Lab expiraram, reconfigure-as na EC2 antes do login no ECR.
- Em aulas futuras (Blue-Green, Canary) o rollback será automatizado.
