FROM node:20-alpine

RUN apk add --no-cache bash git
RUN npm install -g expo-cli

WORKDIR /app


COPY package.json package-lock.json* ./


RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY . .

EXPOSE 19000 19001 19002 19006

CMD ["npm", "run", "start"]
