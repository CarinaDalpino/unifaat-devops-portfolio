# Aula 09 — Docker Registry + IA no CI/CD

[![CI](https://github.com/CarinaDalpino/unifaat-devops-portfolio/actions/workflows/ci.yml/badge.svg)](https://github.com/CarinaDalpino/unifaat-devops-portfolio/actions/workflows/ci.yml)
[![AI Code Review](https://github.com/CarinaDalpino/unifaat-devops-portfolio/actions/workflows/ai-review.yml/badge.svg)](https://github.com/CarinaDalpino/unifaat-devops-portfolio/actions/workflows/ai-review.yml)

Pipeline completo da TechNova API: build e push de imagem para o GitHub Container Registry (ghcr.io) + AI code review automatizado em Pull Requests.

**Aluno:** Carina Dal Pino — **RA:** 6325109

---

## Estrutura

Os workflows ficam na **raiz** do repositório (exigência do GitHub Actions). A aplicação vive em `aula-09/`.

```
unifaat-devops-portfolio/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml              # lint -> test -> build+push (push condicional)
│   │   ├── ai-review.yml       # AI review em PRs (comenta + quality gate)
│   │   └── security-scan.yml   # scan de secrets e Dockerfile em PRs
│   └── scripts/
│       └── ai-review.js        # análise do diff por regras + quality gate
└── aula-09/
    ├── Dockerfile              # multi-stage, usuário não-root, HEALTHCHECK
    ├── .dockerignore
    ├── server.js
    ├── package.json
    ├── __tests__/
    ├── screenshots/            # evidências do TF
    ├── ia-cicd-analise.md      # documentação da estratégia e análise crítica
    └── README.md
```

---

## Pipeline CI (`ci.yml`)

```
lint ──> test ──> build-and-push
                   (apenas em push para main/tags, não em PRs)
```

### Tags geradas

| Evento | Tags |
|--------|------|
| Push para `main` | `sha-XXXXXXX`, `latest` |
| Git tag `v1.2.3` | `1.2.3`, `1.2`, `1`, `sha-XXXXXXX` |
| Pull Request | nenhuma (não publica) |

Imagem publicada em: `ghcr.io/carinadalpino/technova-api`

---

## AI Review (`ai-review.yml` + `.github/scripts/ai-review.js`)

- Dispara em `pull_request` (opened, synchronize, reopened).
- Coleta o diff (`git diff origin/<base>...HEAD`).
- Analisa linhas adicionadas contra 9 padrões (secrets, eval, SQL injection, console.log, catch vazio, etc.).
- Posta/atualiza um comentário no PR com tabela de achados por severidade.
- **Quality gate:** achado CRITICAL -> `exit 1` -> PR bloqueado.

Detalhes e análise crítica em [`ia-cicd-analise.md`](./ia-cicd-analise.md).

---

## Como testar localmente

### Build e execução da imagem

```bash
cd aula-09
docker build -t technova-api:local .
docker run -d -p 3000:3000 --name technova technova-api:local
curl http://localhost:3000/health
docker stop technova && docker rm technova
```

### Lint e testes

```bash
cd aula-09
npm install
npm run lint
npm test
```

### Testar o AI review localmente

```bash
git diff origin/main...HEAD > /tmp/pr-diff.txt
DIFF_FILE=/tmp/pr-diff.txt node .github/scripts/ai-review.js
```

Se houver achado CRITICAL, o comando termina com código de saída 1.

---

## Checklist de evidências (TF)

- [ ] Imagem publicada no ghcr.io com tags (sha, latest, semver) — `screenshots/packages-tab.png`
- [ ] Comentário do AI review em um PR — `screenshots/ai-review-comment.png`
- [ ] Pipeline CI completo verde — `screenshots/pipeline-passing.png`
- [ ] Quality gate bloqueando PR com CRITICAL — `screenshots/quality-gate-block.png`
