# Profile Navigator

A macOS menu bar app that intercepts links and lets you pick which browser profile to open them in.

When you click a link anywhere on your Mac, Profile Navigator shows a small picker instead of opening your default browser directly. Select a profile, optionally save the choice for that domain, and the link opens in the right browser profile.

## Features

- Auto-detects profiles from Chrome, Brave, Edge, Vivaldi, Arc, and Chromium
- Keyboard-driven picker (number keys, arrows, Enter, Esc)
- Remembers domain → profile rules
- Reorder and rename profiles
- CLI tool for scripting

## Requirements

- macOS 13+
- At least one Chromium-based browser installed (Chrome, Brave, Edge, etc.)

## Install

### Homebrew

```sh
brew install --cask kristoffer88/tap/profile-navigator
```

### Build from source

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. Clone the repo and generate the Xcode project:
   ```
   git clone https://github.com/kristoffer88/ProfileNavigator
   cd ProfileNavigator
   xcodegen
   ```
3. Open `ProfileNavigator.xcodeproj` and build (⌘B)
4. Copy `ProfileNavigator.app` to `/Applications`

### Set as default browser

Open **System Settings → Desktop & Dock → Default web browser** and select Profile Navigator.

## Usage

Click any link — the picker appears. Use the keyboard or click to choose a profile.

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate |
| `1`–`9` | Open profile directly |
| `Enter` | Confirm selection |
| `R` or `Tab` | Cycle through site, page, one-time, and never-ask modes |
| `Esc` | Cancel |

### Menu bar

Click the Profile Navigator icon in the menu bar to set a default profile or remove remembered rules. Open **Settings** (⌘,) to manage visible profiles and rename them.

### CLI

A Bun-based CLI is included for scripting from a repository checkout. Install its dependencies once with `bun install --cwd cli`, then run:

```
bun cli/src/index.ts profiles                    # list detected profiles
bun cli/src/index.ts default get                 # show current default
bun cli/src/index.ts default set <id>            # set default profile
bun cli/src/index.ts rules list                  # show remembered domain rules
bun cli/src/index.ts rules set <host> <id>       # add or update a rule
bun cli/src/index.ts rules remove <host>         # remove a rule
bun cli/src/index.ts filter set <id> [<id>...]   # show only specific profiles
bun cli/src/index.ts filter clear                # show all profiles
bun cli/src/index.ts never list                  # list hosts that bypass the picker
bun cli/src/index.ts never remove <host>         # ask again for a host
```

Add `--json` to any CLI command for machine-readable output.

## How it works

Profile Navigator registers itself as the handler for `http://` and `https://` URLs. When a link is opened, it reads browser profile data from `~/Library/Application Support/<browser>/Local State`, presents the picker, then launches the browser executable with `--profile-directory=<dir>`. A running Chromium browser forwards the request to the selected profile.

Config is stored at `~/Library/Application Support/ProfileNavigator/config.json`.

## License

MIT
