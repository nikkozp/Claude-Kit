---
name: azure-pipelines
description: CI/CD using Azure Pipelines (build/push Docker image to a registry, deploy). Use for any pipeline, CI, or deployment change. NOT GitHub Actions.
---

# Azure Pipelines (CI/CD)

This repo ships via **Azure Pipelines** (`azure-pipelines.yml`). NEVER use GitHub Actions for this repo.

## Pipeline Shape
- **Trigger:** `main`/`master` branch.
- **Variables:** `<secrets-variable-group>` variable group (registry creds, third-party keys, etc.) + `imageRepository`, `tag = $(Build.BuildId)`.
- **Pool:** `ubuntu-latest`.
- **Stages:** `Build` (build + push Docker image) -> `Deploy` (to target host/environment, `dependsOn: Build`, `condition: succeeded()`).

## Build & Push (Docker)
```yaml
- task: Docker@2
  inputs: { command: login, containerRegistry: '<registry-connection>' }
- script: |
    docker build \
      --build-arg BUILD_CONFIGURATION=Release \
      -t $(REGISTRY_USERNAME)/$(imageRepository):$(tag) \
      -t $(REGISTRY_USERNAME)/$(imageRepository):latest \
      -f $(dockerfilePath) .
- script: |
    docker push $(REGISTRY_USERNAME)/$(imageRepository):$(tag)
    docker push $(REGISTRY_USERNAME)/$(imageRepository):latest
```

## Adding CI Tests (recommended)
Insert a job before Build:
```yaml
- script: dotnet test --configuration Release --logger trx
  displayName: 'Run tests'
```
Publish results with `PublishTestResults@2`.

## Conventions
- Secrets ALWAYS come from `<secrets-variable-group>` — never inline literals in YAML. Reference as `$(VAR)`.
- Tag images with both `$(Build.BuildId)` and `latest`.
- Keep the Docker layer order in the Dockerfile cache-friendly (csproj copy -> restore -> source -> build).
- Migrations run on app startup (`ApplyMigrations()`) — no separate pipeline migration step; ensure DB is reachable on deploy.

## Rules
- Don't introduce GitHub Actions or `gh`. Don't print secrets in logs. Make pipeline edits minimal and reversible; validate YAML.

See `.claude/rules/migrations.md` for why no separate migration step is needed and `.claude/rules/docker.md` for the Dockerfile conventions this pipeline builds against.
