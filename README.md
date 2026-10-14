# Setup

1. Create a `.env` file containing any API keys you want to use with Pi, eg:

```
DEEPSEEK_API_KEY=sk-11111aaaa11111aaaaaa111111aaaa
OPENROUTER_API_KEY=sk-11111aaaa11111aaaaaa111111aaaa
```

2. Mount any agent config you need (see [Agent settings](#agent-settings))
3. Launch the container with `docker-compose up -d`
4. Pair the Paseo app (see [Paseo](#paseo)) or attach a shell with `docker exec -it pi sh`

## Git identity

Pi commits from inside the container, which needs a git identity. Set `GIT_USER_NAME` and `GIT_USER_EMAIL` (for example in `.env`); `entrypoint.sh` writes them into the container's global git config on every start:

```
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=you@example.com
```

Both are optional and independent: leaving one unset leaves that field at git's default. A repository's own `.git/config` still takes precedence, so clear any per-repo `user.name`/`user.email` if you want this identity to apply there.

> Without either variable, git falls back to `root@<container-host>` (or fails, if it cannot detect a hostname).

## Paseo

The container runs the [Paseo](https://paseo.sh) daemon alongside Pi, so you can drive Pi from the Paseo mobile and desktop apps. `entrypoint.sh` starts it with `paseo daemon run`, supervises it, restarts it if the launcher exits, and sends its logs to the container's stdout (`docker logs pi`).

Paseo finds `pi` on `PATH` and uses Pi's JSONL sessions under `~/.pi`, so there is no wrapper or custom provider. The daemon runs as the same user as Pi.

### Pairing a device

The relay is outbound-only; the container publishes no Paseo port. State lives in `~/.paseo`, mounted from `./paseo-config`, so pairing survives `docker compose restart` and recreation.

Pair the first device from an interactive terminal (the `--relay` flag enables the relay, which stays enabled):

```bash
docker exec -it pi paseo daemon pair --relay
```

This prints a QR code and a pairing link. The link is a credential. Treat it like a password: don't paste it into logs, issues, or the repo. Once the relay is enabled, later devices pair with:

```bash
docker exec -it pi paseo daemon pair
```

The container name is `pi` (the compose service). Substitute your own if you renamed it.

### Rotating the pairing credential

`paseo daemon pair` reprints the same offer every time, and restarting the daemon does not change it. The offer is derived from `~/.paseo/server-id` and `~/.paseo/daemon-keypair.json`. To rotate it, stop the daemon, remove the keypair, and start it again:

```bash
docker exec pi paseo daemon stop
docker exec pi rm ~/.paseo/daemon-keypair.json
docker compose restart pi
```

Previously paired devices have to pair again. Removing the whole `./paseo-config` directory resets all Paseo state.

### Security and configuration

- The daemon binds `127.0.0.1:6767` inside the container. No Paseo port is published and relay traffic is outbound only.
- `PASEO_PASSWORD` is required if you change `PASEO_LISTEN` to bind beyond loopback. `entrypoint.sh` refuses to start Paseo in that case. The default loopback setup needs no password.
- `PASEO_DISABLED=1` skips the daemon; Pi still starts and the container stays up. The default is `0`.
- Local speech/dictation is off by default (`PASEO_DICTATION_ENABLED=false`, `PASEO_VOICE_MODE_ENABLED=false`) because it downloads large models on first run. Set either to `true` to enable it.
- Paseo's version is pinned by the `PASEO_VERSION` build arg in the `Dockerfile`.

## Migration from PI WEB

Port `8504` and the PI WEB processes (`pi-web-sessiond` and `pi-web-server`) were removed. There is no automatic migration:

- Paseo replaces PI WEB for remote access. Pair again with the command above.
- `~/.pi-web` is no longer started or persisted, but existing data on disk is left untouched.
- If a reverse proxy pointed at `8504`, repoint it at whatever you use for Paseo. The container no longer listens on that port.

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
  "packages": ["https://github.com/willthong/agent-skills"]
}
```

- Without a ref, Pi tracks the repository's default branch (`main`) and pulls the latest commit on every update — so skills refresh on each `docker compose up -d` (`entrypoint.sh` runs `pi update --extensions` before starting pi).
- To pin for reproducibility, append a tag or commit ref (`@v1`); pinned refs are reconciled but never moved by `pi update`. Bump deliberately with `pi install git:github.com/willthong/agent-skills@new-ref`.
- Pi clones the package to `~/.pi/agent/git/<host>/<path>`, which persists back into `pi-config/` on the host.

> **Security:** skills can instruct the model to run arbitrary commands. Review the contents of any skills repository before installing it.
