# Flutter Mobile App - Production Build
# Multi-stage build for optimized image size

FROM ghcr.io/nicko170/flutter:latest AS builder

WORKDIR /app

# Copy pubspec and fetch dependencies
COPY pubspec.yaml .
RUN flutter pub get

# Copy source code
COPY lib/ ./lib/
COPY assets/ ./assets/
COPY web/ ./web/

# Build for web (PWA)
RUN flutter build web --release

# Nginx stage for serving the PWA
FROM nginx:alpine AS production

# Copy built web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Custom nginx config for SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]