---
name: setup-new-app
description: This skill should be used when the user asks to "create a new app", "set up a new service", "deploy a new site", "create a new express server", "create a new react app", "create a new full stack app", or wants to provision a new web application on the DreamCompute server.
---

# Setup New App

This skill provisions new web applications on the DreamCompute server (root.noshado.ws) by running setup scripts over SSH. The scripts also create a GitHub repo and wire up a GitHub Actions workflow that deploys to DreamCompute on every push to `main`.

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
4. Ask the user if the GitHub repo should be private. If yes, pass `--private`. Default is public.
5. Run the setup script via SSH with CLI flags:

ssh leo@root.noshado.ws '~/scripts/setup-new-express-server.sh --name "My Service" [--id my-service] [--domain my-service.noshado.ws] [--private]'

ssh leo@root.noshado.ws '~/scripts/setup-new-react-app.sh --name "My App" [--id my-app] [--domain my-app.leo.gd] [--private]'

ssh leo@root.noshado.ws '~/scripts/setup-new-full-stack-app.sh --name "My App" [--id my-app] [--domain my-app.leo.gd] [--private]'

6. Clone the repo into ~/Developer from GitHub: `git clone git@github.com:leomancini/{id}.git ~/Developer/{id}`

## CLI Flags

- --name (required) — app/service name in title case
- --id (optional) — auto-derived from name by lowercasing and hyphenating
- --domain (optional) — auto-derived from id as {id}.noshado.ws (express) or {id}.leo.gd (react/full-stack)
- --anthropic (optional, Express/Full Stack only) — enable Anthropic API access
- --anthropic-key (optional, Express/Full Stack only) — the Anthropic API key to use
- --private (optional) — create the GitHub repo as private (default is public)

## Environment

- The scripts handle everything: directory creation, file scaffolding, npm install, PM2 setup, Apache vhost, SSL via Let's Encrypt, git repo initialization, server-side post-receive deploy hook, GitHub repo creation under `leomancini/{id}`, GitHub Actions deploy workflow at `.github/workflows/deploy.yml`, and the `DREAMCOMPUTE_DEPLOY_KEY` repo secret.
- Deploy flow: pushing to `main` on GitHub triggers the Actions workflow, which pushes to the DreamCompute remote and fires the post-receive hook (install, build if applicable, restart via PM2 for express/full-stack).

## After Setup

1. `cd` into the cloned repo at `~/Developer/{id}`
2. If Anthropic API access was enabled, create a `.env` file in the cloned repo with `ANTHROPIC_API_KEY=<key>` (using the key provided by the user in step 3). The `.env` is gitignored — it lives only on the server and locally, not on GitHub.
3. Run `npm install`
4. Start the local dev server by running `npm run dev` in the background (using `run_in_background: true`)
5. Report back to the user:
   - The live URL: https://{domain}
   - The GitHub repo: https://github.com/leomancini/{id}
   - The local dev server is running
   - Pushing to `main` on GitHub deploys automatically via Actions
