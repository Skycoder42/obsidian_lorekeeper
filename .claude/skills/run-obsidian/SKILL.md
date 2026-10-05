---
name: run-obsidian
description: Run the plugin in a real Obsidian instance and interact with it — enable the plugin, click UI elements, evaluate JS against the Obsidian API, read computed styles and take screenshots. Use to verify UI or styling changes, reproduce plugin errors at runtime, or whenever the user asks to start, run, test or screenshot the plugin in Obsidian.
---

# Run Obsidian

`scripts/run-obsidian.sh` starts the locally installed Obsidian on a throwaway
copy of `testing/PluginTestVault`, enables the plugin and drives the window via
the Chrome DevTools Protocol (CDP). Obsidian is stopped and all temporary files
are removed when the script exits, so the user's Obsidian config and the test
vault stay untouched.

## Workflow

1. Build first: `npm run build`. The vault copy symlinks `main.js` and
   `styles.css` from the repository root, so the latest build is used. The
   styles need build_runner output (see CLAUDE.md).
2. Run the script with the steps to perform. Use a Bash timeout of at least
   120000 ms, as startup can take up to ~25s:

   ```sh
   bash .claude/skills/run-obsidian/scripts/run-obsidian.sh [options] [step...]
   ```

3. Look at screenshots with the Read tool. They are saved to
   `$TMPDIR/run-obsidian/` by default (`-o DIR` to change).

Without steps, the script clicks the plugin's ribbon icon and saves the opened
modal as `modal.png`.

## Steps

Steps run in order after the plugin is loaded. Each is a single argument:

| Step | Effect |
| --- | --- |
| `eval:JS` | Evaluates JS in the Obsidian window and prints the JSON result. Promises are awaited, `app` is the Obsidian `App`. |
| `click:SELECTOR` | Clicks the first element matching the CSS selector. |
| `wait:SELECTOR` | Waits up to 10s for an element matching the CSS selector. |
| `sleep:MS` | Waits for MS milliseconds. |
| `screenshot:NAME` | Saves a PNG screenshot of the window. |

The script exits with 1 on the first failing step. Console errors, warnings and
uncaught exceptions of the window are printed as `[console.error]`,
`[console.warning]` and `[exception]`, which is where plugin errors show up.

Example: open the modal, click a button and check the result and its styles:

```sh
bash .claude/skills/run-obsidian/scripts/run-obsidian.sh \
  'click:[aria-label="Open Lorekeeper"]' \
  'wait:.modal .counter' \
  'click:.counter button:last-child' \
  'eval:document.querySelector(".counter span").textContent' \
  'eval:getComputedStyle(document.querySelector(".counter button")).boxShadow' \
  'screenshot:counter.png'
```

Use `eval` with `getComputedStyle` to debug styling: Obsidian's own CSS (e.g.
the default `button` box shadow) often overrides plugin styles. Every
invocation starts a fresh Obsidian, so put all steps that depend on each other
into one call.

## Gotchas

These are handled by the script, but matter when changing it or running
Obsidian manually:

- Obsidian only lives as long as the Bash command that started it. Launching it
  in one command and driving it in another does not work, which is why the
  script does both.
- VS Code sets `ELECTRON_RUN_AS_NODE`, which makes electron run as plain node
  (`Cannot find module 'electron'`). It must be unset.
- `XDG_CONFIG_HOME` must point to a writable directory. Otherwise KDE shows a
  dialog on the user's desktop that `~/.config/electronrc` is not writable.
- Obsidian deletes and recreates its CLI socket `$XDG_RUNTIME_DIR/.obsidian-cli.sock`
  on startup and removes it on quit. Without a separate `XDG_RUNTIME_DIR`, a
  test instance breaks the CLI of the user's running Obsidian. `WAYLAND_DISPLAY`
  must then be made absolute to keep the display working.
- The DevTools protocol runs over `--remote-debugging-pipe`, not a TCP port: any
  local process could connect to a port and run code with node access in the
  window. Likewise, `eval` steps have full node access, so only pass trusted
  code.
- The window opens on the user's display, so the user can see it.
- A separate `--user-data-dir` with an `obsidian.json` listing only the vault
  copy makes Obsidian open that vault directly.
- New vaults start in restricted mode with a "trust author" dialog. The script
  enables community plugins via `app.plugins.setEnable(true)` and removes the
  dialog.
- Do not use `pkill -f` with a pattern contained in your own command, it kills
  the shell running it.

## Sandbox requirements

Electron needs Unix sockets, which the Bash sandbox blocks by default
(`socket() failed: Operation not permitted`). The sandbox setting
`"sandbox": { "network": { "allowAllUnixSockets": true } }` is required. If it is
missing, tell the user instead of working around it — changing the sandbox is
their decision.
