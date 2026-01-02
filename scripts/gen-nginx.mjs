import fs from "node:fs";
import path from "node:path";

import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, "..");
const OUT_FILE = path.join(ROOT, "docker", "nginx", "conf.d", "routes.generated.conf");
const ENV_FILE = path.join(ROOT, ".env");

// Minimal YAML parser for limited schema (key: value, nested "dev:", and list "apps:")
function parseYaml(raw) {
  const obj = {};
  const lines = raw.split(/\r?\n/);
  let currentListKey = null;
  let currentItem = null;
  let currentMapKey = null;

  for (let line of lines) {
    if (!line.trim() || line.trim().startsWith("#")) continue;
    const indent = line.match(/^\s*/)[0].length;
    const t = line.trim();

    // map key (e.g. dev:)
    if (t.endsWith(":") && t.includes(":") && !t.startsWith("- ")) {
      const key = t.slice(0, -1).trim();
      // apps: is list, everything else treat as map
      if (key === "apps") {
        obj[key] = obj[key] ?? [];
        currentListKey = key;
        currentItem = null;
        currentMapKey = null;
      } else {
        obj[key] = obj[key] ?? {};
        currentMapKey = key;
        currentListKey = null;
        currentItem = null;
      }
      continue;
    }

    // list item under apps:
    if (currentListKey === "apps" && t.startsWith("- ")) {
      currentItem = {};
      obj.apps.push(currentItem);
      currentMapKey = null;
      const rest = t.slice(2).trim();
      if (rest.includes(":")) {
        const idx = rest.indexOf(":");
        const k = rest.slice(0, idx).trim();
        const v = rest.slice(idx + 1).trim().replace(/^"|"$/g, "");
        currentItem[k] = v;
      }
      continue;
    }

    // list item fields
    if (currentListKey === "apps" && currentItem && indent >= 2 && t.includes(":")) {
      const idx = t.indexOf(":");
      const k = t.slice(0, idx).trim();
      const v = t.slice(idx + 1).trim().replace(/^"|"$/g, "");
      currentItem[k] = v;
      continue;
    }

    // fields under dev:
    if (currentMapKey && indent >= 2 && t.includes(":")) {
      const idx = t.indexOf(":");
      const k = t.slice(0, idx).trim();
      const v = t.slice(idx + 1).trim().replace(/^"|"$/g, "");
      obj[currentMapKey][k] = v;
      continue;
    }

    // top-level key: value
    if (t.includes(":")) {
      const idx = t.indexOf(":");
      const k = t.slice(0, idx).trim();
      const v = t.slice(idx + 1).trim().replace(/^"|"$/g, "");
      obj[k] = v;
    }
  }
  return obj;
}

function readEnv() {
  const env = {};
  if (!fs.existsSync(ENV_FILE)) return env;
  const raw = fs.readFileSync(ENV_FILE, "utf8");
  for (const line of raw.split(/\r?\n/)) {
    if (!line || line.trim().startsWith("#")) continue;
    const idx = line.indexOf("=");
    if (idx === -1) continue;
    env[line.slice(0, idx).trim()] = line.slice(idx + 1).trim();
  }
  return env;
}

const env = readEnv();
const DEFAULT_PHP = (env.DEFAULT_PHP || "82").replace(/[^0-9]/g, "") || "82";

const phpUpstream = {
  "74": "php74:9000",
  "82": "php82:9000",
  "84": "php84:9000",
  "85": "php85:9000",
};

function normalizePath(p) {
  return (p || "").replace(/^\.?\/?/, "");
}

function normalizeUrlPath(p) {
  if (!p) return "/";
  let s = p.trim();
  if (!s.startsWith("/")) s = "/" + s;
  if (s.length > 1 && s.endsWith("/")) s = s.slice(0, -1);
  return s;
}

function discoverDevkitFiles() {
  const projectsDir = path.join(ROOT, "projects");
  const found = [];
  if (!fs.existsSync(projectsDir)) return found;

  function walk(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        const dk = path.join(full, ".devkit", "devkit.yml");
        if (fs.existsSync(dk)) found.push(dk);
        walk(full);
      }
    }
  }
  walk(projectsDir);
  return [...new Set(found)];
}

function inferProjectPath(devkitFile) {
  const projDir = path.dirname(path.dirname(devkitFile));
  return path.relative(ROOT, projDir).replace(/\\/g, "/");
}

function routesFromDevkit(filePath) {
  const raw = fs.readFileSync(filePath, "utf8");
  const cfg = parseYaml(raw);

  const makeRoute = (a) => ({
    domain: a.domain,
    url_path: normalizeUrlPath(a.url_path || a.urlPath || "/"),
    type: a.type,
    php: a.php,
    path: a.path || inferProjectPath(filePath),
    docroot: a.docroot ?? (a.type === "static" ? "." : "public"),
    dev: a.dev, // { port: 1234, host: '...' }
    source: filePath,
  });

  const routes = [];
  if (Array.isArray(cfg.apps) && cfg.apps.length) {
    for (const a of cfg.apps) routes.push(makeRoute(a));
  } else {
    routes.push(makeRoute(cfg));
  }

  return routes.filter(r => r.domain && r.type && r.path);
}

const devkitFiles = discoverDevkitFiles();
let routes = [];
for (const f of devkitFiles) routes = routes.concat(routesFromDevkit(f));
routes.sort((a, b) => (a.domain + a.url_path).localeCompare(b.domain + b.url_path));

let conf = `# AUTO-GENERATED. DO NOT EDIT.\n# Sources: projects/**/.devkit/devkit.yml\n\n`;
conf += `upstream php74 { server ${phpUpstream["74"]}; }\n`;
conf += `upstream php82 { server ${phpUpstream["82"]}; }\n`;
conf += `upstream php84 { server ${phpUpstream["84"]}; }\n`;
conf += `upstream php85 { server ${phpUpstream["85"]}; }\n\n`;

if (!routes.length) {
  conf += `# No routes found. Add: projects/<name>/.devkit/devkit.yml\n`;
} else {
  // group by domain into one server block per domain (support multiple url_path entries)
  const byDomain = new Map();
  for (const r of routes) {
    if (!byDomain.has(r.domain)) byDomain.set(r.domain, []);
    byDomain.get(r.domain).push(r);
  }

  for (const [domain, items] of byDomain.entries()) {
    conf += `server {\n`;
    conf += `  listen 80;\n`;
    conf += `  server_name ${domain};\n\n`;

    for (const r of items) {
      const isPHP = r.type === "php";
      const phpVer = (r.php || DEFAULT_PHP).replace(/[^0-9]/g, "");
      const upstreamName = `php${phpUpstream[phpVer] ? phpVer : DEFAULT_PHP}`;

      const projPath = normalizePath(r.path).replace(/^projects\//, "");
      const docroot = normalizePath(r.docroot || (isPHP ? "public" : "."));
      const baseRoot = `/var/www/projects/${projPath}`;
      const fsRoot = path.posix.join(baseRoot, docroot === "." ? "" : docroot);

      const urlPath = normalizeUrlPath(r.url_path);

      conf += `  # Source: ${r.source}\n`;

      if (urlPath === "/") {
        // Proxy to dev server if configured
        if (r.dev && r.dev.port) {
             const devHost = r.dev.host || "node";
             const devPort = r.dev.port;
             // Proxy everything to dev server
             conf += `  location / {\n`;
             conf += `    proxy_pass http://${devHost}:${devPort};\n`;
             conf += `    proxy_http_version 1.1;\n`;
             conf += `    proxy_set_header Upgrade $http_upgrade;\n`;
             conf += `    proxy_set_header Connection "upgrade";\n`;
             conf += `    proxy_set_header Host $host;\n`;
             conf += `  }\n\n`;
        } else if (isPHP) {
          conf += `  root ${fsRoot};\n  index index.php index.html;\n\n`;
          conf += `  location / { try_files $uri $uri/ /index.php?$query_string; }\n\n`;
          conf += `  location ~ \\.php$ {\n`;
          conf += `    include fastcgi_params;\n`;
          conf += `    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n`;
          conf += `    fastcgi_param PHP_VALUE "display_errors=1 \\n error_reporting=E_ALL";\n`;
          conf += `    fastcgi_pass ${upstreamName};\n`;
          conf += `  }\n\n`;
        } else {
          conf += `  root ${fsRoot};\n  index index.html;\n\n`;
          conf += `  location / { try_files $uri $uri/ /index.html; }\n\n`;
        }
      } else {
        // Path-prefix routing using alias so URL does NOT include docroot
        // Example: url_path=/controlroom, docroot=public -> /controlroom/* maps to .../controlroom/public/*
        const aliasRoot = fsRoot; // directory that contains index.php or index.html
        const pfx = urlPath;

        if (isPHP) {
          conf += `  location ^~ ${pfx}/ {\n`;
          conf += `    alias ${aliasRoot}/;\n`;
          conf += `    index index.php index.html;\n`;
          conf += `    try_files $uri $uri/ ${pfx}/index.php?$query_string;\n`;
          conf += `  }\n\n`;

          conf += `  location ~ ^${pfx}/(.+\\.php)$ {\n`;
          conf += `    alias ${aliasRoot}/$1;\n`;
          conf += `    include fastcgi_params;\n`;
          conf += `    fastcgi_param SCRIPT_FILENAME $request_filename;\n`;
          conf += `    fastcgi_param PHP_VALUE "display_errors=1 \\n error_reporting=E_ALL";\n`;
          conf += `    fastcgi_pass ${upstreamName};\n`;
          conf += `  }\n\n`;
        } else {
          conf += `  location ^~ ${pfx}/ {\n`;
          conf += `    alias ${aliasRoot}/;\n`;
          conf += `    index index.html;\n`;
          conf += `    try_files $uri $uri/ ${pfx}/index.html;\n`;
          conf += `  }\n\n`;
        }
      }
      // If dev proxy is active for a subpath? (Not standard use case but possible)
      if (urlPath !== "/" && r.dev && r.dev.port) {
             const devHost = r.dev.host || "node";
             const devPort = r.dev.port;
             conf += `  location ${urlPath}/ {\n`;
             conf += `    proxy_pass http://${devHost}:${devPort};\n`;
             conf += `    proxy_http_version 1.1;\n`;
             conf += `    proxy_set_header Upgrade $http_upgrade;\n`;
             conf += `    proxy_set_header Connection "upgrade";\n`;
             conf += `    proxy_set_header Host $host;\n`;
             conf += `  }\n\n`;
      }
    }

    conf += `}\n\n`;
  }
}

fs.mkdirSync(path.dirname(OUT_FILE), { recursive: true });
fs.writeFileSync(OUT_FILE, conf, "utf8");
console.log(`[devkit] Generated: ${path.relative(ROOT, OUT_FILE)}`);
console.log(`[devkit] Domains: ${new Set(routes.map(r => r.domain)).size}`);
console.log(`[devkit] Routes: ${routes.length}`);
