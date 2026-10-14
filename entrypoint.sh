#!/bin/sh

# ------------------------------------------------------------------
# Git authentication
# ------------------------------------------------------------------

# Configure git auth if GH_TOKEN is provided (GitHub CLI)
if [ -n "$GH_TOKEN" ]; then
    export GH_TOKEN
    gh auth setup-git 2>/dev/null
fi

# Configure git to use GITHUB_PAT for HTTPS operations (GitHub)
# This token is available as GITHUB_PAT in the environment.
# The AI assistant can use it for git operations against GitHub.
if [ -n "$GITHUB_PAT" ]; then
    # Write a credential helper script that reads the token from the env var at runtime
    cat > /usr/local/bin/git-credential-gh-pat << 'GIT_HELPER'
#!/bin/sh
# Git credential helper that reads GITHUB_PAT from the environment
# Called by git when authenticating to GitHub via HTTPS.
read input
echo "username=x-access-token"
echo "password=${GITHUB_PAT}"
GIT_HELPER
    chmod +x /usr/local/bin/git-credential-gh-pat
    export GITHUB_PAT
    git config --global credential.https://github.com.helper /usr/local/bin/git-credential-gh-pat
fi

# ------------------------------------------------------------------
# pi packages (skills, extensions)
# ------------------------------------------------------------------

# Reconcile pinned git refs and refresh packages from settings
# (e.g. skills loaded from a git repo via the "packages" setting).
# Non-fatal: if this fails, pi still starts below.
pi update --extensions

# ------------------------------------------------------------------
# Signal handling
# ------------------------------------------------------------------

# Stop the Paseo daemon and the pi pipeline cleanly on SIGTERM/SIGINT.
# Variables are set later; the guards keep shutdown safe if a signal
# arrives before they are assigned.
PASEO_STOP_FILE="/tmp/paseo-supervisor.stop"

shutdown() {
    trap - TERM INT
    touch "$PASEO_STOP_FILE" 2>/dev/null
    if [ -n "$PASEO_SUPERVISOR_PID" ]; then
        paseo daemon stop --home "$PASEO_HOME" >/dev/null 2>&1
        wait "$PASEO_SUPERVISOR_PID" 2>/dev/null
    fi
    if [ -n "$PI_PIPELINE_PID" ]; then
        kill "$PI_PIPELINE_PID" 2>/dev/null
    fi
    exit 0
}
trap shutdown TERM INT

# ------------------------------------------------------------------
# Paseo daemon
# ------------------------------------------------------------------

# Paseo state (config, daemon identity/keypair, agents) lives in ~/.paseo,
# mounted from the host so pairing survives restarts and recreation.
PASEO_HOME="${PASEO_HOME:-$HOME/.paseo}"

if [ "$PASEO_DISABLED" = "1" ] || [ "$PASEO_DISABLED" = "true" ] || [ "$PASEO_DISABLED" = "yes" ]; then
    echo "Paseo disabled (PASEO_DISABLED=$PASEO_DISABLED)"
else
    # Bind to loopback by default. Paseo's relay is outbound-only, so the
    # mobile/desktop apps do not need a published port.
    PASEO_LISTEN="${PASEO_LISTEN:-127.0.0.1:6767}"

    # Local speech/dictation download large models on first run; default off.
    PASEO_DICTATION_ENABLED="${PASEO_DICTATION_ENABLED:-false}"
    PASEO_VOICE_MODE_ENABLED="${PASEO_VOICE_MODE_ENABLED:-false}"

    export PASEO_HOME PASEO_LISTEN PASEO_DICTATION_ENABLED PASEO_VOICE_MODE_ENABLED

    # Refuse to expose an unauthenticated daemon beyond loopback.
    case "$PASEO_LISTEN" in
        127.0.0.1:*|localhost:*|unix:*|/*) ;;
        *)
            if [ -z "$PASEO_PASSWORD" ]; then
                echo "FATAL: PASEO_LISTEN=$PASEO_LISTEN is not loopback but PASEO_PASSWORD is unset." >&2
                echo "Set PASEO_PASSWORD, bind PASEO_LISTEN to loopback, or set PASEO_DISABLED=1." >&2
                exit 1
            fi
            ;;
    esac

    rm -f "$PASEO_STOP_FILE"

    # Run the daemon in the foreground of a supervised background loop. It
    # inherits this entrypoint's stdout/stderr (so `docker logs` shows it) and
    # is restarted if the launcher exits. `paseo daemon run` already restarts
    # the daemon worker on crash; this loop restarts the launcher itself.
    supervise_paseo() {
        while [ ! -f "$PASEO_STOP_FILE" ]; do
            paseo daemon run --home "$PASEO_HOME"
            status=$?
            if [ -f "$PASEO_STOP_FILE" ]; then
                break
            fi
            echo "paseo: daemon exited (status $status), restarting in ${PASEO_RESTART_DELAY:-5}s" >&2
            sleep "${PASEO_RESTART_DELAY:-5}"
        done
    }
    supervise_paseo &
    PASEO_SUPERVISOR_PID=$!
fi

# ------------------------------------------------------------------
# PI WEB
# ------------------------------------------------------------------

if [ "$PI_WEB_DISABLED" = "1" ] || [ "$PI_WEB_DISABLED" = "true" ]; then
    echo "PI WEB disabled (PI_WEB_DISABLED=$PI_WEB_DISABLED)"
else
    # The session daemon owns agent sessions and terminals; the web server
    # serves the UI/API. Bind 0.0.0.0 so the published container port works.
    pi-web-sessiond &
    PI_WEB_HOST=0.0.0.0 PI_WEB_PORT=8504 pi-web-server &
fi

# ------------------------------------------------------------------
# pi startup
# ------------------------------------------------------------------

# Keep the container alive by piping from a never-ending source.
# pi --mode rpc reads JSON commands from stdin, but we never send any,
# so it blocks on read forever. Run the pipeline in the background and
# wait so the signal trap above runs promptly instead of waiting on a
# foreground child.
tail -f /dev/null | pi --mode rpc &
PI_PIPELINE_PID=$!
wait "$PI_PIPELINE_PID"
