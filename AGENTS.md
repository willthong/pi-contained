# pi-contained

A Docker-based container setup for running the pi coding agent in an isolated environment.

## Key files
- `Dockerfile` — Container image definition
- `docker-compose.yaml` — Docker Compose orchestration
- `entrypoint.sh` — Container entry point script
- `.pi/settings.json` — pi project settings

## Conventions
- Branch naming: `wt/<feature-name>`
- All changes should be tested with `docker compose build` before pushing
