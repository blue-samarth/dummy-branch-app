FROM python:3.11-slim as builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-slim

ARG FLASK_ENV=production
ARG HEALTHCHECK_INTERVAL=30s
ARG HEALTHCHECK_TIMEOUT=5s
ARG HEALTHCHECK_RETRIES=3

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=${FLASK_ENV}
ENV HEALTHCHECK_INTERVAL=${HEALTHCHECK_INTERVAL}
ENV HEALTHCHECK_TIMEOUT=${HEALTHCHECK_TIMEOUT}
ENV HEALTHCHECK_RETRIES=${HEALTHCHECK_RETRIES}

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local

WORKDIR /app

COPY . .

EXPOSE 8000

CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:8000", "wsgi:app"]
