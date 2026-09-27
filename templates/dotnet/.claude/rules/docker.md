---
paths:
  - "**/Dockerfile"
  - "**/docker-compose*.yml"
---
# Docker Rules

The app ships as a Docker image: multi-stage build (.NET SDK -> ASP.NET runtime — check the
target framework in `Directory.Build.props`/`*.csproj` for the exact tag). Production typically
runs via `docker-compose.prod.yml` (app + SQL Server). Adjust the image/service names below to
match your actual Dockerfile and compose files.

## Image (multi-stage)
- `mcr.microsoft.com/dotnet/sdk:<version>` (build/publish) -> `mcr.microsoft.com/dotnet/aspnet:<version>` (runtime).
- Run as non-root (`USER $APP_UID`), listen on `8080` inside the container.
- Layer order: copy `.csproj` files -> `dotnet restore` -> copy source -> `build` -> `publish`. Preserve it for cache hits.
- DataProtection keys persist to a volume (e.g. `/app/keys`) if the app needs a stable key ring across restarts.

## Local Build & Run
```bash
# Build the image
docker build \
  --build-arg BUILD_CONFIGURATION=Release \
  -t <app>:local \
  -f src/<App>.API/Dockerfile .

# Bring up the production-like stack (needs .env with SA_PASSWORD, etc.)
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f <app>
docker compose -f docker-compose.prod.yml down
```

## Compose (prod-like)
- Services: `mssql` (SQL Server, port 1433, volume for `mssql_data`) + the app (port mapped to `8080` inside the container).
- Config via env with double-underscore nesting for nested config sections, e.g. `Database__ConnectionString`.
- The app service `depends_on: mssql`; migrations apply on startup — no separate migration step.
- Never hardcode secrets in the Dockerfile or compose files — use `.env` (gitignored) locally and pipeline variable groups / secret stores in CI, referenced as `<secrets-variable-group>`.

## Rules
- Do NOT change base image major versions without updating the target framework and CI together.
- Keep the layer order (csproj copy -> `dotnet restore` -> copy source -> build) to preserve build-cache efficiency.
- Migrations are NOT run by a separate step — the app applies them on startup. Ensure the DB container is healthy first (`depends_on`).
- For local dev without Docker, run the API project directly; SQL Server can still come from the compose service.
- Keep secrets out of the image and logs; ensure DB health before the app needs it.

See `.claude/skills/azure-pipelines/SKILL.md` for how the image is built and pushed in CI.
