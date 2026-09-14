import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const { build } = await import('esbuild');

await build({
    entryPoints: [join(root, 'assets/scripts/core/Sim.ts')],
    outfile: join(root, 'preview/sim.js'),
    bundle: true,
    format: 'esm',
    platform: 'neutral',
    target: 'es2018',
    logLevel: 'info',
});
console.log('wrote preview/sim.js');
