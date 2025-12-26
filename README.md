# Dev Workstation Kit


## Installation (important)

This repository is designed to be cloned **as the `devkit/` directory**.

**Correct setup:**
```bash
git clone git@github.com:ozanmora/dev-workstation-kit.git devkit
```

**Do NOT clone it like this:**
```bash
git clone git@github.com:ozanmora/dev-workstation-kit.git .
```

Why this matters:
- Internal paths (`./bin/devkit`, `projects/`, `templates/`) assume the repo root **is** `devkit`
- Makefile and VS Code tasks rely on this layout
- Avoids Windows PowerShell path resolution issues

After cloning:
```bash
cp .env.example .env
./bin/devkit bootstrap
```
A portable local dev stack with:
- Traefik (HTTPS edge) + internal Nginx
- PHP-FPM: 7.4 / 8.2 / 8.4 / 8.5
- MariaDB + Redis + Memcached
- Mailpit + Adminer
- Node container for npm/yarn

Project routing is defined per project via:
- `projects/<repo>/.devkit/devkit.yml`

---

## Quick start

### 1) Bootstrap
```bash
cp .env.example .env
./bin/devkit bootstrap
```

### 2) Clone a project
```bash
cd projects
git clone git@github.com:you/demo-app.git demo-app
cd demo-app
```

### 3) Create `.devkit` (Laravel / CI4-style public docroot)
```bash
../../bin/devkit init --domain demo.local.test --public --php 84
```

### 4) Apply routing and start
```bash
cd ../..
make gen
make up
```

Open:
- Project: `https://demo.local.test`
- Adminer: `https://adminer.local.test`
- Mailpit: `https://mailpit.local.test`

---

## Documentation
- Detailed usage: `docs/usage.md`
- Traefik notes: `docs/traefik.md`
- `.devkit` config reference: `docs/devkit-config.md`
- VS Code: `docs/vscode.md`

> PHP 8.5 is experimental; the `redis` PHP extension may not be available there.
