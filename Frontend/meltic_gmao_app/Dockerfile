# Build stage — imagen oficial de Flutter con versión fija (reproducible)
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build
WORKDIR /app

# Instalar dependencias primero (cache de capas Docker)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar código fuente y compilar
COPY . .
RUN flutter build web --release --no-tree-shake-icons

# Run stage — nginx sirve la web compilada
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
