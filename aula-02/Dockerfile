FROM node:20-alpine

WORKDIR /app

# Copiar apenas os arquivos de dependências primeiro
# para aproveitar o cache de camadas do Docker
COPY package*.json ./

# Instalar apenas dependências de produção
RUN npm install --production

# Copiar o restante do código
COPY . .

EXPOSE 3000

CMD ["node", "app.js"]
