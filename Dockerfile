###############################################
# STAGE 1 — Build Vite React frontend
###############################################
FROM node:20 AS frontend-builder

WORKDIR /app/frontend

# Copy only frontend dirs
COPY client/ ./ 
COPY data/ ./data/

# Install deps
RUN npm install

# Build frontend
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

# Install pip deps
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY . .

# Copy built frontend into backend (if your backend serves it)
# adjust path if your Flask app expects static files elsewhere
COPY --from=frontend-builder /app/frontend/dist ./client_build/

# Environment
ENV PYTHONUNBUFFERED=1 \
    FLASK_APP=server:create_app \
    PORT=8000

EXPOSE 8000

###############################################
# STAGE 3 — Final image
###############################################
FROM backend AS final

# Default command is web process
CMD ["gunicorn", "shubble:app", "--bind", "0.0.0.0:8000", "--log-level", "info"]
