# Aula 08 — CI Pipeline com GitHub Actions | TechNova API

![CI Aula 08](https://github.com/CarinaDalpino/unifaat-devops-portfolio/actions/workflows/ci-aula08.yml/badge.svg)

**Aluno:** Carina Gonçalves dos Santos Dalpino
**RA:** 6325109
**Disciplina:** DevOps — Centro Universitário UniFAAT

## Descrição

API Node.js/Express (TechNova) com pipeline de Integração Contínua completo no
GitHub Actions. O pipeline executa em `push` para a main e em `pull_request`, com
três estágios encadeados: **lint → test → build**.

## Pipeline CI (`.github/workflows/ci-aula08.yml`)

```
[push / PR] → lint (ESLint) → test (Jest + coverage) → build (Docker + smoke test)
```

| Job | O que faz | Depende de |
|-----|-----------|------------|
| lint | Roda ESLint no código | — |
| test | Jest com coverage, em Node 18 e 20 (matrix) | lint |
| build | Docker build + smoke test no /health | test |

### Recursos usados
- **Multi-stage** com `needs` (lint → test → build)
- **Matrix strategy** (Node 18 e 20) — bônus B1
- **Cache de dependências** (setup-node com cache npm) — bônus B2
- **Concurrency control** (cancela runs antigos) — bônus B4
- **Smoke test** no container após o build — bônus B5
- **Secret** `AWS_REGION` referenciado no job build (R5)

## Rotas da API

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | /health | Health check |
| GET | /api/orders | Lista pedidos |
| GET | /api/orders/:id | Busca pedido por id |
| POST | /api/orders | Cria pedido |

## Como rodar localmente

```bash
npm install
npm run lint     # ESLint
npm test         # Jest com coverage
docker build -t technova-api .
```

## Secret configurado

O repositório tem o secret `AWS_REGION` (valor fictício para o exercício),
referenciado no workflow com `${{ secrets.AWS_REGION }}`. O GitHub mascara o
valor nos logs.