---
name: profilenavigator
description: |
  Read and configure Profile Navigator — the macOS browser profile router.
  USE FOR: listing profiles, reading/writing rules (domain → profile), setting default, managing the picker filter
  DO NOT USE FOR: launching browsers, changing browser settings, anything outside the ProfileNavigator config
  INVOKES: profilenavigator CLI (cli/src/index.ts)
---

# Profile Navigator CLI

## Setup

```bash
cd /Users/kristoffer/repos/BrowserSwitch && bun run cli/src/index.ts <command>
```

Always prefix Bash commands with `cd /Users/kristoffer/repos/BrowserSwitch &&` — the tool does not preserve cwd.

---

## Commands

### List profiles

```bash
bun run cli/src/index.ts profiles --json
```

Returns all detected profiles with their IDs, display names, and which browser they belong to.

```json
[
  { "id": "Google Chrome|Default", "name": "Kristoffer", "browserApp": "Google Chrome", "isDefault": true },
  { "id": "Google Chrome|Profile 1", "name": "Work", "browserApp": "Google Chrome", "isDefault": false }
]
```

Profile IDs follow the pattern `<browserApp>|<directoryName>`. These are the IDs used everywhere else.

### Default profile

```bash
bun run cli/src/index.ts default get --json
# { "defaultProfileId": "Google Chrome|Default" }

bun run cli/src/index.ts default set "Google Chrome|Profile 1" --json
# { "defaultProfileId": "Google Chrome|Profile 1" }
```

### Domain rules

Rules map a hostname to a profile — Profile Navigator uses them to auto-select a profile for known domains.

```bash
bun run cli/src/index.ts rules list --json
# { "github.com": "Google Chrome|Default", "work.internal": "Google Chrome|Profile 1" }

bun run cli/src/index.ts rules set github.com "Google Chrome|Default" --json
# { "host": "github.com", "profileId": "Google Chrome|Default" }

bun run cli/src/index.ts rules remove github.com --json
# { "removed": "github.com", "existed": true }
```

### Picker filter

Controls which profiles appear in the picker popup. If no filter is set, all profiles are shown.

```bash
bun run cli/src/index.ts filter list --json
# { "visibleProfileIds": ["Google Chrome|Default", "Google Chrome|Profile 1"] }
# or { "visibleProfileIds": null }  ← no filter, all visible

bun run cli/src/index.ts filter set "Google Chrome|Default" "Google Chrome|Profile 1" --json
# { "visibleProfileIds": ["Google Chrome|Default", "Google Chrome|Profile 1"] }

bun run cli/src/index.ts filter clear --json
# { "visibleProfileIds": null }
```

---

## Config file

All settings are stored at:
```
~/Library/Application Support/ProfileNavigator/config.json
```

The CLI reads and writes this file directly. Changes take effect immediately in the running app.

---

## Common tasks

**"Which profile should I use for X?"** — run `profiles --json`, check `isDefault` and `rules list --json`.

**"Route this domain to a profile"** — use `rules set <host> <profileId>`. Get the profile ID from `profiles --json`. Use `rules list` to inspect existing rules and `rules remove` to delete.

**"Show only certain profiles in the picker"** — use `filter set <id> <id> ...` with the exact IDs from `profiles --json`.
