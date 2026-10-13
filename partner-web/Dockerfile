FROM node:24-alpine AS build
WORKDIR /app
COPY partner-web/package*.json ./
RUN npm ci --ignore-scripts
COPY partner-web/ .
ENV NUXT_PUBLIC_API_BASE=/api
ENV NUXT_PUBLIC_DEMO_MODE=true
RUN npx nuxt generate

FROM nginx:stable-alpine
COPY --from=build /app/.output/public /usr/share/nginx/html
COPY partner-web/demo.nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
