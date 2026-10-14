# Setup

1. Create a `.env` file containing any API keys you want to use with Pi, eg:

```
DEEPSEEK_API_KEY=sk-11111aaaa11111aaaaaa111111aaaa
OPENROUTER_API_KEY=sk-11111aaaa11111aaaaaa111111aaaa
```

2. Mount any agent config you need (see [Agent settings](#agent-settings))
3. Launch the container with `docker-compose up -d`
4. Open the web UI at http://localhost:8504, or pair the Paseo app (see [Paseo](#paseo))

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

## PI WEB

The container serves the [PI WEB](https://pi-web.dev) web UI on port 8504. `entrypoint.sh` starts two background processes:

- `pi-web-sessiond` — long-lived session daemon that owns agent sessions and terminals
- `pi-web-server` — web/API server, served on port 8504

The container binds `0.0.0.0:8504` internally and `docker-compose.yaml` publishes the port on all host interfaces, so any machine on the LAN can reach it at `http://<host>:8504`. PI WEB has no built-in authentication, so only expose it this way on a trusted network.

To run the container without the web UI, set `PI_WEB_DISABLED=1` (for example in `.env`):

```
PI_WEB_DISABLED=1
```

The default is `0`. Pi still starts and the container stays up, but neither PI WEB process is launched.

> PI WEB state is stored at `~/.pi-web` inside the container, which is not currently persisted across container recreation. Mount a volume there if you need sessions to survive `docker compose down`.

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
