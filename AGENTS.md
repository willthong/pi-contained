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

## Conventions
- Branch naming: `wt/<feature-name>`
- All changes should be tested with `docker compose build` before pushing
