# stage 1: build
FROM python:3.10-slim as build
WORKDIR /app
COPY requirements.txt .
RUN pip install --upgrade pip && pip wheel -r requirements.txt --wheel-dir=/wheels

# stage 2: runtime
FROM python:3.10-slim
WORKDIR /app
COPY --from=build /wheels /wheels
RUN pip install --no-index --find-links=/wheels -r /app/requirements.txt
COPY . .
ENV PORT=5000
EXPOSE 5000

# healthcheck
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD curl -f http://localhost:5000/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app", "--workers", "2"]