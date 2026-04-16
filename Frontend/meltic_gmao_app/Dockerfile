# Build stage — imagen oficial de Flutter (versión estable para compatibilidad con Dart 3.10+)
FROM ghcr.io/cirruslabs/flutter:stable AS build
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
