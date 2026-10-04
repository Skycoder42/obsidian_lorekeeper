import esbuild from 'esbuild';
import process from 'process';
import { execFile } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';

const prod = process.argv[2] === 'production';

// Writes the @css styles of the plugin to styles.css, which obsidian loads
// automatically. They are printed by the runner that jaspr_builder generates for
// lib/styles.client.dart, so build_runner must have run before.
const stylesRunner = '.dart_tool/build/generated/obsidian_lorekeeper/lib/styles.client.styles.dart';
async function writeStyles() {
  if (!existsSync(stylesRunner)) {
    throw new Error(`${stylesRunner} not found, run build_runner first`);
  }
  const { stdout } = await promisify(execFile)('dart', ['run', stylesRunner]);
  await writeFile('styles.css', JSON.parse(stdout).css);
}

// Compiles imported .dart files with dart2js and bundles the output as JS. The
// styles are generated in parallel.
const dartPlugin = {
  name: 'dart',
  setup(build) {
    // Keeps watching the last known inputs if a compilation fails. The styles
    // runner is watched as well, as build_runner updates it for new @css rules.
    const lastWatchFiles = new Map();
    build.onLoad({ filter: /\.dart$/ }, async (args) => {
      const outDir = await mkdtemp(join(tmpdir(), 'esbuild-dart-'));
      const outFile = join(outDir, 'out.js');
      try {
        await Promise.all([
          promisify(execFile)('dart', [
            'compile',
            'js',
            '--csp',
            '--no-source-maps',
            prod ? '-O2' : '-O1',
            '-o',
            outFile,
            args.path,
          ]),
          writeStyles(),
        ]);
        const deps = await readFile(`${outFile}.deps`, 'utf8');
        const watchFiles = deps
          .split('\n')
          .filter((line) => line.startsWith('file://'))
          .map((line) => fileURLToPath(line))
          .concat(stylesRunner);
        lastWatchFiles.set(args.path, watchFiles);
        return {
          contents: await readFile(outFile, 'utf8'),
          loader: 'js',
          watchFiles,
        };
      } catch (e) {
        return {
          errors: [{ text: `Dart build failed:\n${e.stdout ?? ''}${e.stderr ?? e.message}` }],
          watchFiles: lastWatchFiles.get(args.path) ?? [args.path, stylesRunner],
        };
      } finally {
        await rm(outDir, { recursive: true, force: true });
      }
    });
  },
};

const context = await esbuild.context({
  entryPoints: ['lib/main.dart'],
  plugins: [dartPlugin],
  bundle: true,
  // Obsidian evaluates main.js as CommonJS module with its own `require`, which
  // is the only way to access the obsidian API. As the compiled Dart code can
  // only access globals, the API is made available as global for the bindings
  // in lib/src/api, and the plugin class registered by lib/main.dart is
  // exported to obsidian.
  banner: { js: "globalThis.__obsidian = require('obsidian');" },
  footer: { js: 'module.exports = globalThis.__lorekeeperPluginClass;' },
  format: 'cjs',
  target: 'es2021',
  logLevel: 'info',
  sourcemap: prod ? false : 'inline',
  treeShaking: true,
  outfile: 'main.js',
  minify: prod,
});

if (prod) {
  await context.rebuild();
  process.exit(0);
} else {
  await context.watch();
}
