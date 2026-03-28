#!/usr/bin/env bun

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "fs"
import { homedir } from "os"
import { join } from "path"
import { Command } from "commander"

// --- Types ---

interface Config {
  defaultProfileId?: string
  rules?: Record<string, string>
  visibleProfileIds?: string[]
  displayNameOverrides?: Record<string, string>
}

interface Profile {
  id: string
  directoryName: string
  name: string
  browserApp: string
}

// --- Config ---

const CONFIG_PATH = join(homedir(), "Library/Application Support/ProfileNavigator/config.json")

function readConfig(): Config {
  if (!existsSync(CONFIG_PATH)) return {}
  try {
    return JSON.parse(readFileSync(CONFIG_PATH, "utf8")) as Config
  } catch {
    return {}
  }
}

function writeConfig(config: Config): void {
  mkdirSync(join(homedir(), "Library/Application Support/ProfileNavigator"), { recursive: true })
  writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2) + "\n")
}

// --- Profile detection ---

const BROWSERS = [
  { appName: "Google Chrome",         dataPath: "Google/Chrome" },
  { appName: "Google Chrome Dev",     dataPath: "Google/Chrome Dev" },
  { appName: "Google Chrome Canary",  dataPath: "Google/Chrome Canary" },
  { appName: "Brave Browser",         dataPath: "BraveSoftware/Brave-Browser" },
  { appName: "Microsoft Edge",        dataPath: "Microsoft Edge" },
  { appName: "Chromium",              dataPath: "Chromium" },
  { appName: "Vivaldi",               dataPath: "Vivaldi" },
  { appName: "Arc",                   dataPath: "Arc" },
]

function detectProfiles(): Profile[] {
  const support = join(homedir(), "Library/Application Support")
  const profiles: Profile[] = []

  for (const browser of BROWSERS) {
    if (!existsSync(`/Applications/${browser.appName}.app`)) continue

    const localState = join(support, browser.dataPath, "Local State")
    if (!existsSync(localState)) continue

    try {
      const data = JSON.parse(readFileSync(localState, "utf8")) as {
        profile?: { info_cache?: Record<string, { name?: string }> }
      }
      const infoCache = data?.profile?.info_cache
      if (!infoCache) continue

      for (const [dirName, info] of Object.entries(infoCache)) {
        profiles.push({
          id: `${browser.appName}|${dirName}`,
          directoryName: dirName,
          name: info.name ?? dirName,
          browserApp: browser.appName,
        })
      }
    } catch {
      continue
    }
  }

  return profiles.sort((a, b) => {
    if (a.browserApp !== b.browserApp) return a.browserApp.localeCompare(b.browserApp)
    if (a.directoryName === "Default") return -1
    if (b.directoryName === "Default") return 1
    return a.directoryName.localeCompare(b.directoryName)
  })
}

// --- CLI ---

const program = new Command()
  .name("profilenavigator")
  .description("Manage Profile Navigator profiles, rules, and filters")
  .version("1.0.0")

// profilenavigator profiles
program
  .command("profiles")
  .description("List all detected profiles")
  .option("--json", "Output as JSON")
  .action((opts: { json?: boolean }) => {
    const profiles = detectProfiles()
    const config = readConfig()
    const overrides = config.displayNameOverrides ?? {}

    if (opts.json) {
      console.log(JSON.stringify(profiles.map(p => ({
        id: p.id,
        name: overrides[p.id] ?? p.name,
        browserApp: p.browserApp,
        isDefault: p.id === config.defaultProfileId,
      })), null, 2))
      return
    }

    if (profiles.length === 0) {
      console.log("No profiles found. Make sure Chrome (or Brave/Edge) is installed.")
      return
    }
    for (const p of profiles) {
      const marker = p.id === config.defaultProfileId ? "*" : " "
      const name = overrides[p.id] ?? p.name
      console.log(`${marker} [${p.id}]  ${name}  (${p.browserApp})`)
    }
  })

// profilenavigator default get/set
const defaultCmd = program.command("default").description("Manage the default profile")

defaultCmd
  .command("get")
  .description("Show current default profile ID")
  .option("--json", "Output as JSON")
  .action((opts: { json?: boolean }) => {
    const id = readConfig().defaultProfileId ?? null
    if (opts.json) {
      console.log(JSON.stringify({ defaultProfileId: id }))
    } else {
      console.log(id ?? "(none)")
    }
  })

defaultCmd
  .command("set <id>")
  .description("Set default profile")
  .option("--json", "Output as JSON")
  .action((id: string, opts: { json?: boolean }) => {
    const config = readConfig()
    config.defaultProfileId = id
    writeConfig(config)
    if (opts.json) {
      console.log(JSON.stringify({ defaultProfileId: id }))
    } else {
      console.log(`Default set to: ${id}`)
    }
  })

// profilenavigator rules list/remove
const rulesCmd = program.command("rules").description("Manage domain → profile rules")

rulesCmd
  .command("list")
  .description("List all remembered domain rules")
  .option("--json", "Output as JSON")
  .action((opts: { json?: boolean }) => {
    const rules = readConfig().rules ?? {}
    if (opts.json) {
      console.log(JSON.stringify(rules))
      return
    }
    const entries = Object.entries(rules).sort(([a], [b]) => a.localeCompare(b))
    if (entries.length === 0) {
      console.log("No remembered rules.")
    } else {
      for (const [host, profileId] of entries) {
        console.log(`  ${host}  →  ${profileId}`)
      }
    }
  })

rulesCmd
  .command("set <host> <profileId>")
  .description("Add or update a domain rule")
  .option("--json", "Output as JSON")
  .action((host: string, profileId: string, opts: { json?: boolean }) => {
    const config = readConfig()
    if (!config.rules) config.rules = {}
    config.rules[host] = profileId
    writeConfig(config)
    if (opts.json) {
      console.log(JSON.stringify({ host, profileId }))
    } else {
      console.log(`Rule set: ${host}  →  ${profileId}`)
    }
  })

rulesCmd
  .command("remove <host>")
  .description("Remove a domain rule")
  .option("--json", "Output as JSON")
  .action((host: string, opts: { json?: boolean }) => {
    const config = readConfig()
    const existed = !!config.rules?.[host]
    delete config.rules?.[host]
    writeConfig(config)
    if (opts.json) {
      console.log(JSON.stringify({ removed: host, existed }))
    } else {
      console.log(`Removed rule for: ${host}`)
    }
  })

// profilenavigator filter list/set/clear
const filterCmd = program.command("filter").description("Manage visible profiles filter")

filterCmd
  .command("list")
  .description("Show current visible profiles filter")
  .option("--json", "Output as JSON")
  .action((opts: { json?: boolean }) => {
    const ids = readConfig().visibleProfileIds ?? null
    if (opts.json) {
      console.log(JSON.stringify({ visibleProfileIds: ids }))
      return
    }
    if (ids && ids.length > 0) {
      console.log("Visible profiles:")
      for (const id of ids) console.log(`  ${id}`)
    } else {
      console.log("No filter set — all profiles visible.")
    }
  })

filterCmd
  .command("set <ids...>")
  .description("Show only these profiles in the picker")
  .option("--json", "Output as JSON")
  .action((ids: string[], opts: { json?: boolean }) => {
    const config = readConfig()
    config.visibleProfileIds = ids
    writeConfig(config)
    if (opts.json) {
      console.log(JSON.stringify({ visibleProfileIds: ids }))
    } else {
      console.log(`Filter set to ${ids.length} profile(s).`)
    }
  })

filterCmd
  .command("clear")
  .description("Remove filter — show all profiles")
  .option("--json", "Output as JSON")
  .action((opts: { json?: boolean }) => {
    const config = readConfig()
    delete config.visibleProfileIds
    writeConfig(config)
    if (opts.json) {
      console.log(JSON.stringify({ visibleProfileIds: null }))
    } else {
      console.log("Filter cleared — all profiles will be visible.")
    }
  })

program.parse()
