# Análise — Docker Registry e IA no CI/CD

**Aluno:** Carina Dal Pino
**RA:** 6325109
**Aula:** 09 — Docker Registry e IA no CI/CD

---

## 1. Estratégia de Tagging Escolhida

A estratégia adotada combina **três tipos de tag** de forma complementar, aplicadas automaticamente pelo `docker/metadata-action`:

| Tag | Exemplo | Quando é gerada | Para que serve |
|-----|---------|-----------------|----------------|
| **Git SHA** | `sha-a1b2c3d` | Em todo push para `main` | Rastreabilidade total: cada imagem aponta para o commit exato que a gerou. Essencial para rollback preciso e debug. |
| **`latest`** | `latest` | Apenas em push na branch default (`main`) | Conveniência para dev/testes rápidos — sempre o build mais recente da main. |
| **Semver** | `1.2.3`, `1.2`, `1` | Quando há git tag `v*.*.*` | Releases oficiais. A tag flutuante `1.2` sempre aponta para o último patch, permitindo "pin" por minor. |

### Por quê essa combinação?

- **SHA** resolve o problema central do curso (imagem presa no runner e sem rastreabilidade): com `sha-XXXXXXX` sempre sabemos qual código está rodando em produção.
- **`latest`** dá praticidade no dia a dia, mas **nunca** deve ser usada em produção porque não é determinística — dois pulls em momentos diferentes podem trazer imagens diferentes.
- **Semver** comunica intenção para o time e para o deploy (breaking change vs feature vs bugfix) e é vinculada a git tags, mantendo o histórico de releases.

A regra prática: **produção faz deploy por SHA ou semver**, nunca por `latest`.

---

## 2. Padrões que o AI Review Verifica

O script `.github/scripts/ai-review.js` analisa **apenas as linhas adicionadas** do diff do PR (linhas que começam com `+`) e aplica pattern matching contra as seguintes regras:

| # | Padrão detectado | Severidade | Motivo |
|:-:|------------------|:----------:|--------|
| 1 | Secret/credencial hardcoded (`password`, `secret`, `key`, `token` = "...") | 🔴 CRITICAL | Credencial no código-fonte é vazamento de segurança. |
| 2 | AWS Access Key (`AKIA...`) | 🔴 CRITICAL | Chave de acesso AWS exposta. |
| 3 | `eval()` | 🔴 CRITICAL | Permite code injection a partir de input. |
| 4 | Command injection via template literal em `exec()` | 🔴 CRITICAL | Execução de comando com interpolação não sanitizada. |
| 5 | SQL por concatenação de string (`query('...' + ...)`) | 🔴 CRITICAL | SQL injection — deve usar queries parametrizadas. |
| 6 | `console.log/debug/info` | 🟡 WARNING | Log de debug em produção; preferir logger estruturado. |
| 7 | Catch vazio (`catch (e) {}`) | 🟡 WARNING | Erros silenciados escondem bugs. |
| 8 | Binding em `0.0.0.0` | 🟡 WARNING | Verificar exposição de rede intencional. |
| 9 | `TODO`/`FIXME`/`HACK`/`XXX` | 🔵 INFO | Pendências que deveriam ser resolvidas antes do merge. |

São **9 padrões**, acima do mínimo de 5 exigido pelo TF.

---

## 3. Prompt / Lógica Utilizada para a Análise

Nesta implementação (Opção A do laboratório), a análise é feita por **regras determinísticas** (pattern matching com expressões regulares), não por chamada a um LLM. A lógica é:

1. O workflow faz `git diff origin/<base>...HEAD` e salva em `/tmp/pr-diff.txt`.
2. O script lê o diff, identifica o arquivo atual (`+++ b/arquivo`) e, para cada linha adicionada, testa todas as regras.
3. Cada achado recebe severidade (CRITICAL/WARNING/INFO), arquivo, trecho de código e mensagem.
4. Um relatório Markdown é gerado com resumo + tabela de achados.
5. Se houver qualquer CRITICAL, o processo encerra com `exit 1` (quality gate).

> **Caminho para IA real (Opção B):** o mesmo ponto de entrada pode ser trocado por uma chamada ao **AWS Bedrock** (modelo Claude), enviando o diff dentro de um prompt do tipo:
> *"Você é um revisor de código experiente. Analise o diff abaixo e classifique achados em CRITICAL/WARNING/INFO, apontando arquivo, problema e sugestão de correção."*
> A estrutura do relatório e do quality gate permaneceria idêntica — só mudaria a origem dos achados (regras → inferência do modelo).

---

## 4. Lógica de Decisão do Quality Gate

| Severidade | Ação no pipeline | Ação do desenvolvedor |
|:----------:|:----------------:|:---------------------:|
| 🔴 CRITICAL | `exit 1` — reprova o check, PR bloqueado | Correção obrigatória antes do merge |
| 🟡 WARNING | Comenta no PR, check passa | Correção recomendada |
| 🔵 INFO | Comenta no PR, check passa | Opcional |

Para o bloqueio ter efeito real, o check `ai-review` é configurado como **required status check** em Settings → Branches → Branch protection rules na branch `main`. Sem isso, o PR mostra ❌ mas ainda poderia ser mergeado.

---

## 5. Quando Confiar na IA vs Quando Exigir Review Humano

**A IA (ou a análise automatizada) é mais confiável para:**
- Padrões repetitivos e checklists extensos (secrets, injection, console.log).
- PRs grandes, onde o humano perde atenção.
- Feedback imediato fora do horário comercial.
- Padronização para novos contribuidores.

**Apenas humanos revisam bem:**
- Decisões de arquitetura e design.
- Regras de negócio e contexto do domínio.
- Lógica complexa e corretude algorítmica.
- Impacto em UX e trade-offs de produto.

A IA **complementa, não substitui** o review humano. O ideal é: a automação pega o óbvio antes, e o humano foca no que exige julgamento.

---

## 6. Limitações Identificadas

- **Falsos positivos:** a regra de secret casa com qualquer `key = "..."`, podendo apontar código legítimo (ex.: uma chave de objeto). Nesta implementação, uma linha com SQL que também contém `key =` é classificada só uma vez por regra, o que pode esconder um segundo achado na mesma linha.
- **Falsos negativos:** pattern matching não entende semântica — um `eval` indireto ou SQL montado em várias linhas pode passar.
- **Contexto limitado:** a análise vê apenas o diff, não o sistema inteiro, então não avalia impacto arquitetural.
- **Custo e latência (no caminho com LLM):** chamadas a Bedrock/OpenAI cobram por token e levam de 10 a 60 segundos; PRs grandes custam mais.

Por isso o bloqueio por CRITICAL é uma **trava de segurança**, não uma decisão final — em caso de falso positivo, o desenvolvedor corrige ou justifica.
