#!/usr/bin/env bash
# Runs Obsidian with the plugin enabled on a throwaway copy of the test vault and
# drives it via the Chrome DevTools Protocol. Obsidian is stopped and all
# temporary files are removed when the script exits.
#
# Usage: run-obsidian.sh [options] [step...]
#
# Options:
#   -v, --vault DIR  Existing vault to copy (default: testing/PluginTestVault,
#                    created via tool/create-test-vault.sh if missing).
#   -o, --out DIR    Directory for screenshots (default: $TMPDIR/run-obsidian).
#                    It must be a directory owned by the current user.
#
# Steps run in order once the plugin is loaded:
#   eval:JS          Evaluates JS in the Obsidian window (promises are awaited)
#                    and prints the result. `app` is the Obsidian App. The JS
#                    has full node access, so only pass trusted code.
#   click:SELECTOR   Clicks the first element matching the CSS selector.
#   wait:SELECTOR    Waits up to 10s for an element matching the CSS selector.
#   sleep:MS         Waits for MS milliseconds (at most 60000).
#   screenshot:NAME  Saves a PNG screenshot of the window to the out dir. NAME
#                    is a plain file name ending in .png.
#
# Without steps, the plugin's ribbon icon is clicked and the modal screenshotted.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
default_vault="$repo_dir/testing/PluginTestVault"
vault_src="$default_vault"
out_dir="${TMPDIR:-/tmp}/run-obsidian"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v | --vault | -o | --out)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 2
      fi
      case "$1" in
        -v | --vault) vault_src="$2" ;;
        *) out_dir="$2" ;;
      esac
      shift 2
      ;;
    -h | --help) sed -n '2,/^set /p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *) break ;;
  esac
done

if [[ $# -eq 0 ]]; then
  set -- 'click:[aria-label="Open Lorekeeper"]' 'wait:.modal .main' 'sleep:500' 'screenshot:modal.png'
fi

if [[ ! -f "$repo_dir/main.js" ]]; then
  echo "main.js not found, run 'npm run build' first" >&2
  exit 1
fi
# Only the default vault is created, so a mistyped path does not create a
# vault in some random location.
if [[ "$vault_src" == "$default_vault" && ! -e "$vault_src" ]]; then
  "$repo_dir/tool/create-test-vault.sh" "$vault_src"
fi
if [[ ! -d "$vault_src" ]]; then
  echo "Vault not found: $vault_src" >&2
  exit 1
fi
# Screenshots must not end up in a directory someone else controls, e.g. a
# pre-created /tmp/run-obsidian when TMPDIR is not set.
mkdir -p -- "$out_dir"
if [[ -L "$out_dir" || ! -O "$out_dir" ]]; then
  echo "Out dir must be a directory owned by you: $out_dir" >&2
  exit 1
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/run-obsidian.XXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT

# The vault is copied so obsidian cannot modify the original. Plugin files are
# symlinks, so the copy always uses the latest build.
cp -a -- "$vault_src" "$work_dir/vault"
mkdir -p "$work_dir/profile" "$work_dir/config" "$work_dir/runtime"
chmod 700 "$work_dir/runtime"

cat > "$work_dir/cdp.mjs" << 'EOF'
import { spawn } from 'node:child_process';
import { readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const [repoDir, workDir, outDir, ...steps] = process.argv.slice(2);
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Steps are validated before obsidian is started, so mistakes fail fast.
const invalid = (message) => {
  console.error(`Error: ${message}`);
  process.exit(2);
};
const parsed = steps.map((step) => {
  const separator = step.indexOf(':');
  const [kind, arg] = separator < 0 ? [step, ''] : [step.slice(0, separator), step.slice(separator + 1)];
  if (!['eval', 'click', 'wait', 'sleep', 'screenshot'].includes(kind)) invalid(`Unknown step: ${step}`);
  if (['eval', 'click', 'wait'].includes(kind) && !arg) invalid(`Missing argument: ${step}`);
  if (kind === 'sleep' && !(/^\d{1,5}$/.test(arg) && Number(arg) <= 60000)) invalid(`Invalid sleep duration: ${step}`);
  // Plain file names only, so screenshots cannot be written outside the out dir.
  if (kind === 'screenshot' && !/^[\w-][\w.-]*\.png$/.test(arg)) invalid(`Invalid screenshot name: ${step}`);
  return { kind, arg };
});

const pluginId = JSON.parse(readFileSync(join(repoDir, 'manifest.json'), 'utf8')).id;
writeFileSync(
  join(workDir, 'profile', 'obsidian.json'),
  JSON.stringify({ vaults: { run: { path: join(workDir, 'vault'), ts: 1, open: true } } }),
);

// - ELECTRON_RUN_AS_NODE is set by VS Code and would run electron as plain node.
// - XDG_CONFIG_HOME prevents a KDE dialog about ~/.config/electronrc not being
//   writable (it is read-only in the sandbox). It also keeps the obsidian
//   launcher from reading the user's obsidian/user-flags.conf.
// - XDG_RUNTIME_DIR is where obsidian creates its CLI socket, replacing the one
//   of a running obsidian. WAYLAND_DISPLAY is made absolute to keep working.
// - The separate user data dir keeps the user's obsidian config untouched and
//   only knows the vault copy, which is opened directly.
// - The DevTools protocol runs over a pipe instead of a TCP port, which any
//   local process could connect to and execute code through.
const env = { ...process.env, XDG_CONFIG_HOME: join(workDir, 'config'), XDG_RUNTIME_DIR: join(workDir, 'runtime') };
delete env.ELECTRON_RUN_AS_NODE;
if (env.WAYLAND_DISPLAY && !env.WAYLAND_DISPLAY.startsWith('/') && process.env.XDG_RUNTIME_DIR) {
  env.WAYLAND_DISPLAY = join(process.env.XDG_RUNTIME_DIR, env.WAYLAND_DISPLAY);
}
const obsidian = spawn(
  'obsidian',
  [`--user-data-dir=${join(workDir, 'profile')}`, '--remote-debugging-pipe', '--no-sandbox', '--disable-gpu'],
  { env, stdio: ['ignore', 'ignore', 'ignore', 'pipe', 'pipe'] },
);
let exited = false;
obsidian.on('exit', () => (exited = true));
const stop = () => exited || obsidian.kill();
process.on('exit', stop);
for (const signal of ['SIGINT', 'SIGTERM', 'SIGHUP']) {
  process.on(signal, () => process.exit(1));
}

let lastId = 0;
const pending = new Map();
let sessionId;
let buffer = '';
obsidian.stdio[4].setEncoding('utf8');
obsidian.stdio[4].on('data', (chunk) => {
  buffer += chunk;
  for (let end; (end = buffer.indexOf('\0')) >= 0; buffer = buffer.slice(end + 1)) {
    const data = JSON.parse(buffer.slice(0, end));
    if (data.id) {
      pending.get(data.id)?.(data);
      pending.delete(data.id);
    } else if (data.method === 'Runtime.consoleAPICalled' && ['error', 'warning'].includes(data.params.type)) {
      const text = data.params.args.map((a) => a.value ?? a.description ?? a.type).join(' ');
      // Electron always warns about obsidian's CSP in unpackaged mode.
      if (!text.includes('Electron Security Warning')) {
        console.log(`[console.${data.params.type}] ${text}`);
      }
    } else if (data.method === 'Runtime.exceptionThrown') {
      const details = data.params.exceptionDetails;
      console.log(`[exception] ${details.exception?.description ?? details.text}`);
    }
  }
});
obsidian.stdio[3].on('error', () => {});
const send = (method, params = {}, session = sessionId) =>
  new Promise((resolve, reject) => {
    if (exited) return reject(new Error('Obsidian exited'));
    const id = ++lastId;
    pending.set(id, (data) => (data.error ? reject(new Error(data.error.message)) : resolve(data.result)));
    obsidian.stdio[3].write(`${JSON.stringify({ id, method, params, sessionId: session })}\0`);
  });
obsidian.on('exit', () => {
  for (const settle of pending.values()) settle({ error: { message: 'Obsidian exited' } });
});

async function attachToVault() {
  for (let i = 0; i < 120 && !exited; i++) {
    const { targetInfos } = await send('Target.getTargets', {}, undefined);
    const page = targetInfos.find((t) => t.type === 'page' && t.url.startsWith('app://obsidian.md/index.html'));
    if (page) {
      return (await send('Target.attachToTarget', { targetId: page.targetId, flatten: true }, undefined)).sessionId;
    }
    await sleep(500);
  }
  throw new Error('Obsidian vault window not found');
}

const evaluate = async (expression) => {
  const { result, exceptionDetails } = await send('Runtime.evaluate', {
    expression,
    awaitPromise: true,
    returnByValue: true,
  });
  if (exceptionDetails) {
    const description = exceptionDetails.exception?.description ?? exceptionDetails.text;
    throw new Error(description.replace(/^Error: /, ''));
  }
  return result.value;
};

try {
  sessionId = await attachToVault();
  await send('Runtime.enable');
  for (let i = 0; !(await evaluate('!!window.app?.workspace?.layoutReady')); i++) {
    if (i >= 60) throw new Error('Obsidian workspace did not get ready');
    await sleep(500);
  }

  // Turns off restricted mode, enables the plugin and closes the "trust author"
  // dialog shown for new vaults.
  const loaded = await evaluate(`(async () => {
    await app.plugins.setEnable(true);
    await app.plugins.loadManifests();
    await app.plugins.enablePluginAndSave(${JSON.stringify(pluginId)});
    document.querySelectorAll('.modal-container:has(.mod-trust-folder)').forEach((e) => e.remove());
    return !!app.plugins.plugins[${JSON.stringify(pluginId)}];
  })()`);
  if (!loaded) throw new Error(`Plugin ${pluginId} could not be loaded`);
  console.log(`Plugin ${pluginId} loaded`);

  for (const { kind, arg } of parsed) {
    switch (kind) {
      case 'eval':
        console.log(`> ${arg}`);
        console.log(JSON.stringify(await evaluate(arg), null, 2) ?? 'undefined');
        break;
      case 'click':
        await evaluate(`(() => {
          const element = document.querySelector(${JSON.stringify(arg)});
          if (!element) throw new Error('No element matches ' + ${JSON.stringify(arg)});
          element.click();
        })()`);
        console.log(`Clicked ${arg}`);
        break;
      case 'wait':
        await evaluate(`new Promise((resolve, reject) => {
          const start = Date.now();
          const check = () => {
            if (document.querySelector(${JSON.stringify(arg)})) resolve();
            else if (Date.now() - start > 10000) reject(new Error('Timed out waiting for ' + ${JSON.stringify(arg)}));
            else setTimeout(check, 100);
          };
          check();
        })`);
        console.log(`Found ${arg}`);
        break;
      case 'sleep':
        await sleep(Number(arg));
        break;
      case 'screenshot': {
        const { data } = await send('Page.captureScreenshot', { format: 'png' });
        const file = join(outDir, arg);
        // Replaces the file instead of writing through a symlink placed there.
        rmSync(file, { force: true });
        writeFileSync(file, Buffer.from(data, 'base64'), { flag: 'wx' });
        console.log(`Screenshot saved to ${file}`);
        break;
      }
    }
  }
} catch (e) {
  console.error(`Error: ${e.message ?? e.error?.message ?? e}`);
  process.exitCode = 1;
} finally {
  stop();
  await new Promise((resolve) => (exited ? resolve() : obsidian.once('exit', resolve)));
}
EOF

# Not exec'd, so the EXIT trap still removes the work dir afterwards.
node "$work_dir/cdp.mjs" "$repo_dir" "$work_dir" "$out_dir" "$@"
