# Fase 1: Compilación
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

WORKDIR /app
COPY . .

# Limpiamos y construimos para web
RUN flutter build web --release

# Fase 2: Servidor Web ligero (Nginx)
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]