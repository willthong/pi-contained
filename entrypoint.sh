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
# pi startup
# ------------------------------------------------------------------

# Keep pi alive by piping from a never-ending source.
# pi --mode rpc reads JSON commands from stdin, but we never send any,
# so it blocks on read forever while the tau-mirror extension serves the web UI.
tail -f /dev/null | pi --mode rpc
