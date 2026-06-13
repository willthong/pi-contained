#!/usr/bin/env python3
"""Patch tau-mirror's mirror-server.ts to fix the broken /api/instances handler.

See https://github.com/deflating/tau/pull/37
"""
import sys

MIRROR_TS = sys.argv[1]

with open(MIRROR_TS, 'r') as f:
    content = f.read()

old = '    if (urlPath === "/api/instances") {\n\n    if (urlPath === "/api/projects"'
new = '    if (urlPath === "/api/instances") {\n      res.writeHead(200, { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" });\n      res.end(JSON.stringify({ instances: getRunningInstances() }));\n      return;\n    }\n\n    if (urlPath === "/api/projects"'

if old not in content:
    print("Pattern not found - mirror-server.ts may already be patched")
    sys.exit(1)

content = content.replace(old, new)

with open(MIRROR_TS, 'w') as f:
    f.write(content)

print("Patched mirror-server.ts successfully")
