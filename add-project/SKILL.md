---
name: add-project
description: This skill should be used when the user asks to "add a project", "create a project", "add a new project to the site", "add a project to the projects site", or wants to add a project entry to the projects site generator.
---

# Add Project

This skill adds a new project to the projects site generator at `~/Developer/Local Server Root/projects-site-generator`.

## Project Data Model

Each project is a folder inside `projects/` containing:

- `manifest.json` (required) — project metadata
- `longDescription.txt` (optional) — extended description with markdown-style links
- `screenshots/` (optional) — project images
- `downloads/` (optional) — downloadable files

### manifest.json Schema

```json
{
    "name": "Project Name",
    "shortDescription": "One-line description",
    "startDate": {
        "string": "Month Year or Full Date (e.g., 'August 2025' or 'August 17, 2025')"
    },
    "links": [
        {
            "type": "github|document|download|gallery-sign|portfolio|3d_model|live-site",
            "label": "Display Text or DEFAULT_FOR_TYPE",
            "icon": "DEFAULT_FOR_TYPE",
            "url": "https://..."
        }
    ],
    "tags": ["tag1", "tag2"],
    "credits": [
        {
            "name": "Person Name",
            "type": "artist|developer|etc",
            "link": "https://..."
        }
    ]
}
```

Notes:
- `links`, `tags`, and `credits` are all optional. Omit any that don't apply (don't include empty arrays).
- For `label` and `icon`, use `"DEFAULT_FOR_TYPE"` unless the user specifies custom text.
- Tags like `github`, `live-site`, `3d`, `audio`, `video` are auto-generated — do not add them manually.
- The folder name should be a kebab-case version of the project name.

### longDescription.txt Format

Plain text. Links use the format: `[link="url" Link Text]`

## Workflow

1. Run `./pull` from the projects-site-generator directory to sync the latest changes before doing anything else.
2. Ask the user for the project details. At minimum, gather:
   - Project name
   - Short description
   - Start date (month and year, or full date)
3. Optionally gather: links, tags, credits, and a long description. Only include fields the user provides — do not prompt for every optional field unless the user seems to want a thorough entry.
4. Create the project folder at `~/Developer/Local Server Root/projects-site-generator/projects/{folder-name}/`.
5. Write `manifest.json` with the gathered data.
6. If the user provided a long description, write `longDescription.txt`.
7. If the user wants to add screenshots, create the `screenshots/` folder and let them know to place image files there.
8. Ask the user if they want to push the changes now. If yes, run `./push` from the projects-site-generator directory. The push script will prompt for a commit message — use something like "Add {project name}". Note: `./push` reads from stdin for the commit message, so pipe it in: `echo "Add {project name}" | ./push`
