# Build Flutter web. Runtime uses same-origin /api (Uri.base).
# API_UPSTREAM must be set to the Laravel service (default api:8000).
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
ARG API_BASE_URL=
RUN if [ -n "$API_BASE_URL" ]; then \
      flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}; \
    else \
      flutter build web --release; \
    fi

FROM caddy:2-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=builder /app/build/web /srv
ENV PORT=3000
# Must include port. Do not rely on Caddy {$VAR:host:port} defaults (colon breaks parsing).
ENV API_UPSTREAM=api:8000
EXPOSE 3000
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
