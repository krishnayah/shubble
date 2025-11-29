# ----------------------------
# 1. Frontend build stage
# ----------------------------
FROM node:18 AS frontend
WORKDIR /app

COPY client/package.json client/package-lock.json ./client/
RUN cd client && npm install

COPY client ./client
COPY data ./data

RUN cd client && npm run build



# ----------------------------
# 2. Backend stage
# ----------------------------
FROM python:3.12-slim AS backend

WORKDIR /app

# System deps (build-essential for some pip packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install backend dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY server ./server
COPY migrations ./migrations
COPY data ./data
COPY shubble.py .
COPY .flaskenv .

# Copy frontend build into container
COPY --from=frontend /app/client/dist ./client_dist

# Placeholder env vars (Dokploy will override these)
ENV PORT=8000 \
    LOG_LEVEL=info \
    DATABASE_URL=__REPLACE_ME__ \
    SECRET_KEY=__REPLACE_ME__ \
    OTHER_API_KEY=__REPLACE_ME__

EXPOSE 8000

# Default process = web server
CMD ["gunicorn", "shubble:app", "--bind", "0.0.0.0:8000"]
