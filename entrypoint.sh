#!/bin/sh

# Keep pi alive by piping from a never-ending source.
# pi --mode rpc reads JSON commands from stdin, but we never send any,
# so it blocks on read forever while the tau-mirror extension serves the web UI.
tail -f /dev/null | pi --mode rpc
