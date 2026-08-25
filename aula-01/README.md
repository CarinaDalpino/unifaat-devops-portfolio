# Aula 01 — Fundamentos de Git e Docker

## O que aprendi

### Git

- Aprendi a criar e utilizar branches para organizar o desenvolvimento das atividades
- Aprendi a adicionar arquivos ao controle de versão com `git add`
- Aprendi a registrar alterações utilizando `git commit`
- Aprendi a enviar branches para o GitHub utilizando `git push`
- Aprendi a verificar o estado do repositório utilizando `git status`

### Docker

- Aprendi o conceito de containers e sua utilização para executar aplicações de forma isolada
- Aprendi a criar uma imagem Docker utilizando um Dockerfile
- Aprendi a construir uma imagem utilizando `docker build`
- Aprendi a executar um container utilizando `docker run`
- Aprendi a mapear portas do container para a máquina local

## Comandos Git praticados

- `git clone`
- `git status`
- `git branch`
- `git checkout`
- `git checkout -b`
- `git add`
- `git commit`
- `git push`
- `git merge`

## Comandos Docker praticados

- `docker build`
- `docker run`
- `docker ps`
- `docker stop`
- `docker rm`

## Como executar este container

```bash
cd aula-01/app
docker build -t portfolio-aula01:1.0 .
docker run -d -p 3000:3000 portfolio-aula01:1.0
curl http://localhost:3000
```
