---
name: setup-new-app
description: This skill should be used when the user asks to "create a new app", "set up a new service", "deploy a new site", "create a new express server", "create a new react app", "create a new full stack app", or wants to provision a new web application on the DreamCompute server.
---

# Setup New App

This skill provisions new web applications on the DreamCompute server (root.noshado.ws) by running setup scripts over SSH.

## Available App Types

| Type | Script | Default Domain |
|------|--------|----------------|
| Express Server | `setup-new-express-server.sh` | `{id}.noshado.ws` |
| React App | `setup-new-react-app.sh` | `{id}.leo.gd` |
| Full Stack App | `setup-new-full-stack-app.sh` | `{id}.leo.gd` |

## Workflow

1. Determine which app type the user wants. If unclear, ask.
2. Always ask the user for the app/service name (title case, e.g. "My Cool App"). Do not offer to generate a name — the user must provide one. Optionally gather a custom ID or domain.
3. For Express Server or Full Stack App: ask the user if they want to enable Anthropic API access. If yes, prompt for their API key. Then pass `--anthropic --anthropic-key <key>` to the setup script.
4. Run the setup script via SSH with CLI flags:

ssh leo@root.noshado.ws 'DREAMCOMPUTE_LEO_PASSWORD="$DREAMCOMPUTE_LEO_PASSWORD" ~/scripts/setup-new-express-server.sh --name "My Service" [--id my-service] [--domain my-service.noshado.ws]'

ssh leo@root.noshado.ws 'DREAMCOMPUTE_LEO_PASSWORD="$DREAMCOMPUTE_LEO_PASSWORD" ~/scripts/setup-new-react-app.sh --name "My App" [--id my-app] [--domain my-app.leo.gd]'

ssh leo@root.noshado.ws 'DREAMCOMPUTE_LEO_PASSWORD="$DREAMCOMPUTE_LEO_PASSWORD" ~/scripts/setup-new-full-stack-app.sh --name "My App" [--id my-app] [--domain my-app.leo.gd]'

5. Clone the repo into ~/Developer with git clone leo@root.noshado.ws:{apps_directory}/{id}

## CLI Flags

- --name (required) — app/service name in title case
- --id (optional) — auto-derived from name by lowercasing and hyphenating
- --domain (optional) — auto-derived from id as {id}.noshado.ws (express) or {id}.leo.gd (react/full-stack)
- --anthropic (optional, Express/Full Stack only) — enable Anthropic API access
- --anthropic-key (optional, Express/Full Stack only) — the Anthropic API key to use

## Environment

- The DREAMCOMPUTE_LEO_PASSWORD env var must be available to skip the interactive sudo prompt. If it is not set, the script will prompt for the password interactively (which will not work over non-interactive SSH).
- The scripts handle everything: directory creation, file scaffolding, npm install, PM2 setup, Apache vhost, SSL via Let's Encrypt, git repo initialization, and deploy hooks.

## After Setup

1. `cd` into the cloned repo at `~/Developer/{id}`
2. If Anthropic API access was enabled, create a `.env` file in the cloned repo with `ANTHROPIC_API_KEY=<key>` (using the key provided by the user in step 3).
3. Run `npm install`
4. Start the local dev server by running `npm run dev` in the background (using `run_in_background: true`)
5. Report back to the user:
   - The live URL: https://{domain}
   - The local dev server is running