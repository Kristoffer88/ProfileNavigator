---
name: profilenavigator
description: Inspect or configure Profile Navigator profiles, domain routing, defaults, and picker visibility; browser launching and browser settings are outside this skill.
---

# Profile Navigator

From a ProfileNavigator checkout, run the CLI at the project root:

```bash
bun cli/src/index.ts <command>
```

Use `<command> --help` for current syntax. Add `--json` when structured output is useful.

## Workflow

1. Run `profiles --json` to obtain exact profile IDs in `<browser>|<directory>` form.
2. Inspect existing state before changing it:
   - `default get --json`
   - `rules list --json`
   - `filter list --json`
   - `never list --json`
3. Apply only the requested configuration change:
   - `default set <profile-id> --json`
   - `rules set <host> <profile-id> --json`
   - `rules remove <host> --json`
   - `filter set <profile-id>... --json`
   - `filter clear --json`
   - `never remove <host> --json`
4. Read the affected state again and report the result.

Rules map hostnames or host-plus-path keys to profiles. The picker filter limits visible profiles; a cleared filter shows all profiles. The `never` list contains hosts that bypass the picker.

Configuration is stored in `~/Library/Application Support/ProfileNavigator/config.json` and changes take effect in the running app. Use the CLI rather than editing the file directly.