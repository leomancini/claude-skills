---
name: remove-app
description: This skill should be used when the user asks to "remove an app", "delete an app", "tear down a service", "remove a server", "remove a react app", "remove a full stack app", or wants to deprovision a web application from the DreamCompute server.
---

# Remove App

This skill removes web applications from the DreamCompute server (root.noshado.ws) by running removal scripts over SSH.

## Available App Types

| Type | Script | ID Flag |
|------|--------|---------|
| Express Server | `remove-express-server.sh` | `--service-id` |
| React App | `remove-react-app.sh` | `--app-id` |
| Full Stack App | `remove-full-stack-app.sh` | `--app-id` |

## Workflow

1. Gather the app/service ID (e.g. "my-cool-app"). If the user gives a name instead, derive the ID by lowercasing and hyphenating.
2. Auto-detect the app type by checking which directory contains the ID on the server:

```
ssh leo@root.noshado.ws 'if [ -d ~/services/MY_ID ]; then echo "express"; elif [ -d ~/react-apps/MY_ID ]; then echo "react"; elif [ -d ~/full-stack-apps/MY_ID ]; then echo "full-stack"; else echo "not-found"; fi'
```

   - If the result is `not-found`, tell the user no app with that ID exists on the server and stop.
   - Otherwise, use the detected type to select the correct removal script.

3. Confirm with the user before proceeding — this is a destructive action.
4. Run the removal script via SSH with CLI flags:

```
ssh leo@root.noshado.ws 'DREAMCOMPUTE_LEO_PASSWORD="$DREAMCOMPUTE_LEO_PASSWORD" ~/scripts/remove-express-server.sh --service-id "my-service"'

ssh leo@root.noshado.ws 'DREAMCOMPUTE_LEO_PASSWORD="$DREAMCOMPUTE_LEO_PASSWORD" ~/scripts/remove-react-app.sh --app-id "my-app"'

ssh leo@root.noshado.ws 'DREAMCOMPUTE_LEO_PASSWORD="$DREAMCOMPUTE_LEO_PASSWORD" ~/scripts/remove-full-stack-app.sh --app-id "my-app"'
```

5. If a local repo exists at `~/Developer/{id}`, ask the user if they want it deleted too.

## CLI Flags

- Express: `--service-id` (required)
- React / Full Stack: `--app-id` (required)

## Environment

- The DREAMCOMPUTE_LEO_PASSWORD env var must be available to skip the interactive sudo prompt.
- The scripts handle everything: PM2 removal, Apache vhost cleanup, SSL cleanup, directory deletion, and ecosystem.config.js cleanup.

## After Removal

Report back to the user that the app has been removed from the server.
