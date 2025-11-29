###############################################
# STAGE 1 — Build Vite React frontend
###############################################
FROM node:20 AS frontend-builder

WORKDIR /app/client

# Copy only frontend files
COPY client/package*.json ./
COPY client/ ./
COPY data/ ./data/

# Install deps
RUN npm install

# Build Vite app
RUN npm run build


###############################################
# STAGE 2 — Python backend
###############################################
FROM python:3.11-slim AS backend

# System deps (psycopg2 + build tools)
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY . .

# Copy built frontend into backend static directory
COPY --from=frontend-builder /app/client/dist ./client_build/

ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=server:create_app
ENV PORT=8000

EXPOSE 8000

###############################################
# FINAL — Run web process
###############################################
CMD ["gunicorn", "shubble:app", "--bind", "0.0.0.0:8000", "--log-level=info"]
