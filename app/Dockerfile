# Stage 1: Build wheels
FROM python:3.10-slim as build
WORKDIR /app
COPY requirements.txt .
RUN apt-get update && apt-get install -y curl ca-certificates && update-ca-certificates
RUN pip install --upgrade pip && \
    pip wheel --no-cache-dir -r requirements.txt --wheel-dir=/wheels

# Stage 2: Runtime
FROM python:3.10-slim
WORKDIR /app

# Copy pre-built wheels
COPY --from=build /wheels /wheels

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt

# Copy application code
COPY . .

# Environment
ENV PORT=8000
EXPOSE 8000

# Healthcheck
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD curl -f http://localhost:8000/health || exit 1

# Start Gunicorn

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app", "--workers", "2"]
