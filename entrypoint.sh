#!/bin/sh

# Configure git auth if GH_TOKEN is provided
if [ -n "$GH_TOKEN" ]; then
    export GH_TOKEN
    gh auth setup-git 2>/dev/null
fi

# Keep pi alive by piping from a never-ending source.
# pi --mode rpc reads JSON commands from stdin, but we never send any,
# so it blocks on read forever while the tau-mirror extension serves the web UI.
tail -f /dev/null | pi --mode rpc
