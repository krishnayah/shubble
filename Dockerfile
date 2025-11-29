# --- Build client (Vite) ---
FROM node:18-alpine AS frontend-build
WORKDIR /build

# Install dependencies & build client
COPY client/package*.json client/tsconfig.* client/vite.config.* ./client/
# copy full client source
COPY client ./client
WORKDIR /build/client

RUN npm ci --silent
RUN npm run build

# --- Build Python app ---
FROM python:3.12-slim AS python-base
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    POETRY_VIRTUALENVS_CREATE=false

# Install system deps needed for common Python packages (adjust if you know you need more)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd --create-home --shell /bin/bash appuser
WORKDIR /app

# Copy and install python requirements
COPY requirements.txt .
RUN pip install --upgrade pip setuptools wheel
RUN pip install -r requirements.txt

# Copy application source
COPY . /app

# Copy built frontend into Flask static folder.
# The Vite build output is typically in /build/client/dist. We copy its contents into /app/static
# so Flask can serve the static single-page app. Adjust the destination if your app expects otherwise.
COPY --from=frontend-build /build/client/dist /app/static

# Make entrypoint executable (we'll add this file next)
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Make sure app files are owned by non-root user
RUN chown -R appuser:appuser /app /usr/local/bin/docker-entrypoint.sh

USER appuser

# Expose default port (can be overridden by $PORT)
ENV PORT=8000
EXPOSE ${PORT}

# Healthcheck: hits root by default. If your app exposes a /health route, change it here.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD curl -f http://localhost:${PORT} || exit 1

# Entrypoint will optionally run migrations when RUN_MIGRATIONS=true, then exec the CMD
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command uses the same process as your Procfile's web process.
# It expects environment variables PORT and LOG_LEVEL to be provided by the runtime.
CMD ["gunicorn", "shubble:app", "--bind", "0.0.0.0:8000", "--workers", "4", "--log-level", "info"]
