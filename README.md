# BrowserSwitch

A macOS menu bar app that intercepts links and lets you pick which browser profile to open them in.

When you click a link anywhere on your Mac, BrowserSwitch shows a small picker instead of opening your default browser directly. Select a profile, optionally save the choice for that domain, and the link opens in the right browser profile.

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

### Build from source

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. Clone the repo and generate the Xcode project:
   ```
   git clone https://github.com/kristoffer/BrowserSwitch
   cd BrowserSwitch
   xcodegen
   ```
3. Open `BrowserSwitch.xcodeproj` and build (⌘B)
4. Copy `BrowserSwitch.app` to `/Applications`

### Set as default browser

Open **System Settings → Desktop & Dock → Default web browser** and select BrowserSwitch.

## Usage

Click any link — the picker appears. Use the keyboard or click to choose a profile.

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate |
| `1`–`9` | Open profile directly |
| `Enter` | Confirm selection |
| `R` or `Tab` | Toggle "Remember for this domain" |
| `Esc` | Cancel |

### Menu bar

Click the BrowserSwitch icon in the menu bar to set a default profile or remove remembered rules. Open **Settings** (⌘,) to manage visible profiles and rename them.

### CLI

A companion CLI tool is included for scripting:

```
browserswitch profiles                    # list detected profiles
browserswitch default get                 # show current default
browserswitch default set <id>            # set default profile
browserswitch rules list                  # show remembered domain rules
browserswitch rules remove <host>         # remove a rule
browserswitch filter set <id> [<id>...]   # show only specific profiles
browserswitch filter clear                # show all profiles
```

## How it works

BrowserSwitch registers itself as the handler for `http://` and `https://` URLs. When a link is opened, it reads browser profile data from `~/Library/Application Support/<browser>/Local State`, presents the picker, then launches the chosen browser via `/usr/bin/open -a <browser> --args --profile-directory=<dir>`.

Config is stored at `~/Library/Application Support/BrowserSwitch/config.json`.

## License

MIT
