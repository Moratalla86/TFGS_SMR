# Build stage
FROM ubuntu:22.04 AS build
ENV DEBIAN_FRONTEND=noninteractive

# Prerequisites
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils libglu1-mesa python3 libfontconfig1 libgl1-mesa-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter doctor -v
RUN flutter config --enable-web

WORKDIR /app
COPY . .
RUN rm -rf build
RUN flutter pub get
RUN flutter build web --release --no-tree-shake-icons

# Run stage
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
# Custom nginx config to handle SPA routing if needed
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
