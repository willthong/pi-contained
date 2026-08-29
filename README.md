# Setup

1. Create a `.env` file containing any API keys you want to use with Pi, eg:

```
DEEPSEEK_API_KEY=sk-11111aaaa11111aaaaaa111111aaaa
OPENROUTER_API_KEY=sk-11111aaaa11111aaaaaa111111aaaa
```

2. Mount any agent config you need (see [Agent settings](#agent-settings))
3. Launch the container with `docker-compose up -d`

## Agent settings

`docker-compose.yaml` mounts `./pi-config` as the Pi agent home (`/root/.pi`) and `./projects` as `/root/projects`. Place config files inside `pi-config/` to make them visible to Pi in the container:

| Host file | Container path | Purpose |
|---|---|---|
| `pi-config/agent/settings.json` | `~/.pi/agent/settings.json` | Global settings (providers, models, packages) |
| `pi-config/agent/skills/` | `~/.pi/agent/skills/` | Global skills |
| `pi-config/agent/auth.json` | `~/.pi/agent/auth.json` | Model credentials |

### Loading skills from a git repo (recommended)

Keep skills in their own git repository (a `skills/` directory of `SKILL.md` folders, optionally with a `package.json` `pi` manifest) and load them as a Pi package:

```json
// pi-config/agent/settings.json
{
  "packages": ["https://github.com/willthong/pi-skills@v1"]
}
```

- Pin a tag or commit ref (`@v1`); pinned refs are never moved by `pi update`.
- Bump deliberately: `pi install git:github.com/willthong/pi-skills@new-ref`
- Pi clones the package to `~/.pi/agent/git/<host>/<path>`, which persists back into `pi-config/` on the host.
- On container start, `entrypoint.sh` runs `pi update --extensions` to reconcile pinned refs, so skills refresh on every `docker compose up -d`.

**Prerequisites (not yet in this repo):**

- Add `git` to the `apk add` line in the `Dockerfile` (needed to clone git packages).
- Add `pi update --extensions` to `entrypoint.sh` before starting pi.

> **Security:** skills can instruct the model to run arbitrary commands. Review the contents of any skills repository before installing it.
