# Builder stage
FROM python:3.13-slim-bookworm AS builder
COPY --from=docker.io/astral/uv:latest /uv /uvx /bin/

# Set environment variables to prevent Python from writing .pyc files and buffering
ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y build-essential gcc && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN /bin/uv venv && /bin/uv pip install --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.13-slim-bookworm AS final

WORKDIR /app
COPY --from=builder /app/.venv /app/.venv 

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH"

COPY . /app

EXPOSE 5000

CMD ["uvicorn", "main:app"]