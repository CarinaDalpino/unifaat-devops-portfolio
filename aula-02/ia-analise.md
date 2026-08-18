# Análise do Uso de IA — Aula 02 TF

**Aluno:** Carina Gonçalves dos Santos Dalpino
**RA:** 6325109

---

## Prompt Utilizado

> "Crie um docker-compose.yml para uma aplicação Node.js 20 com Express que usa PostgreSQL 15 como banco de dados e Redis 7 como cache. A API roda na porta 3000. O PostgreSQL precisa de volume nomeado para persistência. Todos os serviços devem estar na mesma rede bridge customizada. Use variáveis de ambiente com interpolação de arquivo .env. Adicione healthchecks, depends_on com condition, e restart policy unless-stopped."

---

## Output Original do Kiro

```yaml
services:
  api:
    build: .
    ports:
      - "${PORT:-3000}:3000"
    environment:
      - PORT=${PORT}
      - NODE_ENV=${NODE_ENV}
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=${POSTGRES_DB}
      - DB_USER=${POSTGRES_USER}
      - DB_PASSWORD=${POSTGRES_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - technova-net
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - technova-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    networks:
      - technova-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

networks:
  technova-net:
    driver: bridge

volumes:
  pgdata:
```

---

## Alterações que Fiz Manualmente

| O que mudei | Por quê |
|------------|---------|
| Adicionei `container_name` em cada serviço | Facilita identificar os containers no `docker ps` e nos logs |
| Adicionei `-d ${POSTGRES_DB}` no healthcheck do PostgreSQL | O `pg_isready` sem `-d` valida apenas a conectividade geral; com `-d` garante que o banco correto existe e está acessível |
| Adicionei `start_period` no healthcheck do PostgreSQL (10s) | O PostgreSQL demora para inicializar na primeira vez; sem esse período o container pode ser marcado como unhealthy prematuramente |
| Adicionei `start_period` no healthcheck do Redis (5s) | Mesma razão, evitar falsos negativos na inicialização |
| Separei as variáveis `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` no `.env` | O output do Kiro misturava variáveis do Postgres com variáveis da API; mantive variáveis separadas para cada contexto |
| Adicionei comentários explicativos em cada seção | Melhora a legibilidade e o entendimento para quem ler o arquivo futuramente |

---

## O que o Kiro Acertou

- Estrutura geral do `docker-compose.yml` estava correta e bem organizada
- Uso de `depends_on` com `condition: service_healthy` — boa prática que o Kiro aplicou corretamente
- Interpolação de variáveis com `.env` para evitar senhas hardcoded
- Imagens corretas: `postgres:15-alpine` e `redis:7-alpine`
- `restart: unless-stopped` em todos os serviços
- Volume nomeado `pgdata` para persistência do PostgreSQL
- Rede bridge customizada `technova-net`

---

## O que o Kiro Errou ou Omitiu

- O healthcheck do PostgreSQL não incluía `-d` para validar o banco específico, tornando a verificação incompleta
- Ausência de `start_period` nos healthchecks — pode causar falsos negativos na inicialização do PostgreSQL
- Não adicionou `container_name` — dificulta a identificação dos containers
- Ausência de comentários explicativos no arquivo gerado

---

## Minha Avaliação

- **Tempo economizado usando IA:** ~20 minutos (estrutura base e sintaxe do Compose)
- **Tempo gasto validando/corrigindo:** ~15 minutos (revisar healthchecks, testar localmente, ajustar variáveis)
- **Nota para o output da IA (1-10):** 7
- **Usaria novamente para este tipo de tarefa?** Sim. O Kiro gerou um rascunho sólido como ponto de partida, economizando tempo na escrita da estrutura base. Porém, não substituiu a necessidade de entender o que cada configuração faz — os ajustes nos healthchecks, por exemplo, só foram possíveis porque eu sabia o que `pg_isready` faz e quais parâmetros ele aceita. A IA é um acelerador, não um substituto para o conhecimento técnico.
