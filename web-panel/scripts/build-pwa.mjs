import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dist = path.join(root, 'dist');
const files = [
    'index.html',
    'icon.svg',
    'manifest.webmanifest',
    'icons/icon-192.png',
    'icons/icon-512.png',
    'icons/apple-touch-icon.png',
];
for (const file of fs.readdirSync(path.join(dist, 'assets'))) {
    if (/\.(js|css)$/.test(file)) files.push(`assets/${file}`);
}
files.sort();
const hash = createHash('sha256');
for (const file of files) hash.update(file).update(fs.readFileSync(path.join(dist, file)));
const template = fs.readFileSync(path.join(root, 'pwa/service-worker.js'), 'utf8');
hash.update(template);
const version = hash.digest('hex').slice(0, 16);

const worker = template
    .replace('__CACHE_VERSION__', version)
    .replace('__PRECACHE_FILES__', JSON.stringify(files));
fs.writeFileSync(path.join(dist, 'sw.js'), worker);
console.log(`PWA shell ${version}: ${files.length} static files; no API/game state cached.`);
