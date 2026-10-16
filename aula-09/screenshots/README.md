# Screenshots — Evidências do TF (Aula 09)

Coloque os 4 arquivos de imagem nesta pasta, com exatamente estes nomes:

| Arquivo | O que mostra | Onde capturar |
|---------|--------------|---------------|
| `pipeline-passing.png` | Pipeline CI completo verde (lint → test → build+push) | Actions → workflow **CI** → run com os 3 jobs verdes |
| `packages-tab.png` | Imagem publicada no ghcr.io com tags (latest, sha) | Repositório → seção **Packages** → `technova-api` |
| `ai-review-comment.png` | Comentário do AI review no PR (tabela de achados por severidade) | PR de teste → comentário do bot "AI Code Review - TechNova" |
| `quality-gate-block.png` | Quality gate bloqueando o PR (check ai-review falhando) | PR de teste → seção de checks → `ai-review` com ❌ |

> Após adicionar as imagens, rode:
> ```bash
> git add aula-09/screenshots/
> git commit -m "docs(aula-09): adicionar screenshots de evidencia do TF"
> git push origin main
> ```
