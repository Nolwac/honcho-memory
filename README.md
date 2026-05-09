# honcho-memory

Local Docker stack for [Honcho](https://github.com/plastic-labs/honcho) — an open-source memory and reasoning layer for AI agents.

## Services

| Container | Image | Purpose |
|---|---|---|
| `honcho-db` | `pgvector/pgvector:pg15` | PostgreSQL + pgvector (memory store) |
| `honcho-redis` | `redis:8.2` | Job queue and cache |
| `honcho-api` | `plasticlabs/honcho:latest` | REST API — `POST /v3/workspaces`, dialectic chat, etc. |
| `honcho-deriver` | `plasticlabs/honcho:latest` | Background worker — memory extraction, summaries, dream consolidation |

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose v2)
- An [OpenRouter](https://openrouter.ai/keys) API key (used for all inference and embeddings)
- [`task`](https://taskfile.dev) — cross-platform task runner:

  ```bash
  # macOS
  brew install go-task

  # Windows (pick one)
  choco install go-task
  scoop install task
  winget install Task.Task

  # Linux
  sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
  ```

## Setup

```bash
# 1. Clone
git clone <this-repo> && cd honcho-memory

# 2. Create env files from examples
task init

# 3. Fill in your key (the only required edit)
#    In .env.api and .env.deriver: LLM_OPENROUTER_API_KEY

# 4. Build the honcho image from source (once — takes a few minutes)
task build

# 5. Start
task up

# 5. Verify
make health
```

## Environment files

| File | Read by | Contains |
|---|---|---|
| `.env` | docker compose (port mapping) | Bind addresses and host ports |
| `.env.db` | `honcho-db` container | Postgres credentials |
| `.env.api` | `honcho-api` container | LLM keys, dialectic models, app config |
| `.env.deriver` | `honcho-deriver` container | LLM keys, deriver / summary / dream models |

Each file has a committed `.example` counterpart. Actual `.env*` files are gitignored.

## Model configuration

All inference (including embeddings) routes through [OpenRouter](https://openrouter.ai) using the `openai`-compatible transport. Only one API key needed.

| Task | Model | Cost |
|---|---|---|
| Embeddings | `qwen/qwen3-embedding-8b` | $0.01 per 1M |
| Deriver (background extraction) | `google/gemma-4-31b-it:free` | **FREE** |
| Summary | `google/gemma-4-31b-it:free` | **FREE** |
| Dialectic minimal / low | `google/gemma-4-31b-it:free` | **FREE** |
| Dialectic medium | `nvidia/nemotron-3-super-120b-a12b:free` | **FREE** |
| Dialectic high | `qwen/qwen3.5-flash-02-23` | $0.065 in / $0.26 out per 1M |
| Dialectic max | `deepseek/deepseek-v4-flash` | $0.14 in / $0.28 out per 1M |
| Dream deduction + induction | `deepseek/deepseek-v4-flash` | $0.14 in / $0.28 out per 1M |

All models support tool/function calling, which Honcho requires.

## Makefile commands

```bash
task up        # start all containers (detached)
task down      # stop all containers
task restart   # restart all containers
task logs      # stream logs from all services
task ps        # show container status
task health    # curl the /health endpoint
task shell-db  # open psql inside honcho-db
task reset     # ⚠ destroy containers, volumes, and db_data/
```

## Ports (configurable in `.env`)

| Service | Default |
|---|---|
| Honcho API | `127.0.0.1:8000` |
| PostgreSQL | `127.0.0.1:5432` |
| Redis | `127.0.0.1:6379` |

To expose on a Tailscale or LAN IP, set e.g. `HONCHO_BIND=100.x.x.x` in `.env`.

## Verification

```bash
# Health check
curl http://localhost:8000/health

# Smoke test — create a workspace
curl -X POST http://localhost:8000/v3/workspaces \
  -H "Content-Type: application/json" \
  -d '{"name": "test"}'
```

## Notes

- The **deriver must be running** for memory to work. The API alone accepts data but never processes it.
- Postgres data is stored in `./db_data/` (bind mount, gitignored). Back it up before running `make reset`.
- Switching embedding models requires a schema migration if the new model has a different native output dimension. Honcho's `openai` transport does not pass `dimensions` to the API, so MRL truncation is not available.
- If `plasticlabs/honcho:latest` is not on Docker Hub, clone the repo and switch to a build context — see the comment at the top of `docker-compose.yml`.
