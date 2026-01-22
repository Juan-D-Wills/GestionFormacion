FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS base

# Shared deps builder
FROM base AS deps
WORKDIR /app
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_NO_DEV=1
COPY pyproject.toml uv.lock* ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project

# Dev stage
FROM base AS dev
WORKDIR /app
ENV UV_NO_DEV=0
COPY pyproject.toml uv.lock* ./
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=from=deps,source=/app/.venv,target=/app/.venv \
    uv sync --frozen
COPY . .
EXPOSE 8000
CMD ["uv", "run", "uvicorn","--reload", "main:app", "--host", "0.0.0.0"]

# Prod stage
FROM python:3.13-slim-bookworm AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1001 no-root && useradd --uid 1001 --gid no-root user
WORKDIR /app

ENV PATH="/app/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1
COPY --from=deps --chown=user:no-root /app/.venv ./venv
COPY --chown=user:no-root . .
USER appuser
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0"]