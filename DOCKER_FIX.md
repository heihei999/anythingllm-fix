# Docker Build Fix: Node Version Upgrade (18 → 20)

## Problem

The Docker build failed during `server yarn install` with:

```
error @aws-sdk/client-bedrock-runtime@3.1062.0: The engine "node" is incompatible with this module.
Expected version ">=20.0.0". Got "18.20.8"
```

The dependency `@aws-sdk/client-bedrock-runtime@^3.775.0` requires Node ≥ 20, but the Dockerfile
installed Node 18 from nodesource and used `node:18-slim` for the frontend build stage.

## Root Cause

- `server/package.json` lists `@aws-sdk/client-bedrock-runtime: ^3.775.0` as a dependency
- The resolved version (3.1062.0) declares `engines.node: >=20.0.0`
- `docker/Dockerfile` installed Node 18.x from nodesource (arm64 + amd64 stages)
- `docker/Dockerfile` used `node:18-slim` as the frontend-build base image
- Node 18 reached EOL in April 2025

## Fix Applied

**Upgraded Node 18 → Node 20 in `docker/Dockerfile`** (3 locations):

### Change 1: arm64 stage nodesource repo (line 25)
```diff
- echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main"
+ echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main"
```

### Change 2: amd64 stage nodesource repo (line 94)
```diff
- echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main"
+ echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main"
```

### Change 3: frontend-build base image (line 141)
```diff
- FROM --platform=$BUILDPLATFORM node:18-slim AS frontend-build
+ FROM --platform=$BUILDPLATFORM node:20-slim AS frontend-build
```

## Why This Is the Safest Fix

1. **Node 20 is LTS** (Active LTS until Oct 2026, Maintenance until Apr 2027). Node 18 is EOL.
2. **No dependency changes needed** — all existing packages work with Node 20.
3. **Backward compatible** — `server/package.json` engines field says `>=18.12.1`, so Node 20 satisfies it.
4. **Minimal change surface** — only the Dockerfile is modified; no package.json or lockfile changes.
5. **Industry standard** — Node 20 is the recommended upgrade path from Node 18.

## Alternatives Considered (and rejected)

| Alternative | Why rejected |
|---|---|
| Pin `@aws-sdk/client-bedrock-runtime` to older version | Fragile; other packages may also require Node 20 in future updates |
| Add `--ignore-engines` to yarn install | Masks real compatibility issues; risky |
| Remove `@aws-sdk/client-bedrock-runtime` | Breaks Bedrock functionality |

## Verification

Test build with a minimal Dockerfile confirmed:
- Node v20.20.2 installed successfully
- `yarn install --production` completed without engine errors
- `@aws-sdk/client-bedrock-runtime` installed cleanly
- Full `docker compose build` was blocked by Docker network issues in the build environment (unrelated to this fix)

## Files Modified

- `docker/Dockerfile` — 3 line changes (Node 18 → Node 20)
