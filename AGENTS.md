# pi-contained

A Docker-based container setup for running the pi coding agent in an isolated environment.

## Key files
- `Dockerfile` — Container image definition
- `docker-compose.yaml` — Docker Compose orchestration
- `entrypoint.sh` — Container entry point script
- `.pi/settings.json` — pi project settings

## Credentials

### GitHub PAT
- Available as `GITHUB_PAT` environment variable inside the container
- A git credential helper (`/usr/local/bin/git-credential-gh-pat`) is configured for `https://github.com`
- Use the token for git clone/push/pull operations to GitHub over HTTPS:
  ```bash
  git clone https://github.com/some-org/some-repo.git
  ```
  Authentication is handled automatically by the credential helper.
- To use the token explicitly in API calls: `$GITHUB_PAT`
- For git remote URLs with embedded credentials (e.g., in build steps or CI):
  ```bash
  git remote set-url origin https://x-access-token:${GITHUB_PAT}@github.com/org/repo.git
  ```

## Web UI (PI WEB)
- The container serves PI WEB on port `8504` (`pi-web-sessiond` + `pi-web-server`, started by `entrypoint.sh`).
- Set `PI_WEB_DISABLED=1` to skip both PI WEB processes; the default is `0`.

## Paseo
- The container runs the Paseo daemon (`paseo daemon run`, supervised by `entrypoint.sh`) so Pi can be driven from the Paseo mobile and desktop apps.
- State lives in `~/.paseo` (mounted from `./paseo-config`); no port is published and the relay is outbound only.
- Set `PASEO_DISABLED=1` to skip the daemon; the default is `0`.
- Pair with `docker exec -it pi paseo daemon pair` (`--relay` on first use).

## Conventions
- Branch naming: `wt/<feature-name>`
- All changes should be tested with `docker compose build` before pushing
