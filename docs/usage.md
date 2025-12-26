# Usage

This document covers the full workflow: adding projects, initializing `.devkit`, using Makefile helpers,
Node helpers, and database helpers.

## Core commands

From the DevKit repo root:

```bash
make bootstrap
make gen
make up
make down
make logs
make ps
make reset
```

## Add a project (separate repo)

Clone the repo under `projects/`:

```bash
cd projects
git clone git@github.com:you/demo-app.git demo-app
```

## Initialize `.devkit`

You can run init **inside the project folder**:

### Laravel / CodeIgniter 4 (public docroot)
```bash
cd projects/demo-app
../../bin/devkit init --domain demo.local.test --public --php 84
```

### WordPress (docroot = project root)
```bash
cd projects/wp-site
../../bin/devkit init --domain wp.local.test --wordpress --php 82
```

### Plain PHP
```bash
cd projects/plain-site
../../bin/devkit init --domain plain.local.test --php 82 --docroot public
```

### Serve under a URL prefix (path-based routing)
```bash
cd projects/demo-app
../../bin/devkit init --domain demo.local.test --url-path /portal --public --php 84
```

### Static / React build
```bash
cd projects/ui
../../bin/devkit init --domain ui.local.test --type static --docroot build
```

### React dev server (domain:port)
Store the dev port as metadata:

```bash
cd projects/ui
../../bin/devkit init --domain ui.local.test --type static --docroot build --dev-port 5173
```

Run your dev server so it binds to all interfaces:

```bash
yarn dev --host 0.0.0.0 --port 5173
```

Then open:
- `http://ui.local.test:5173`

## Makefile init wrappers (recommended from repo root)

These wrappers `cd` into the project folder before running `devkit init`:

### PHP
```bash
make init-php PROJECT=projects/demo-app DOMAIN=demo.local.test PHP=84 PUBLIC=1
```

If your PHP project uses the repository root as docroot:
```bash
make init-php PROJECT=projects/legacy-site DOMAIN=legacy.local.test PHP=74 PUBLIC=0 DOCROOT=.
```

### WordPress
```bash
make init-wp PROJECT=projects/wp-site DOMAIN=wp.local.test PHP=82
```

### Static
```bash
make init-static PROJECT=projects/ui DOMAIN=ui.local.test DOCROOT=build DEVPORT=5173
```

## Apply changes

After adding or editing `.devkit/devkit.yml`:

```bash
make gen
make up
```

## PHP helpers

Shell into specific PHP containers:

```bash
make php74
make php82
make php84
make php85
```

Composer:

```bash
make composer84 ARGS="install -d /var/www/projects/demo-app"
```

## Database helpers

```bash
make mysql
make mysql-root
make mysql-dump OUT=backup.sql
make mysql-import IN=backup.sql
```

## Node helpers (npm/yarn)

```bash
make yarn ARGS="-C projects/ui install"
make yarn ARGS="-C projects/ui build"

make npm  ARGS="-- --prefix projects/ui run build"
```

## Templates

Template folders live under `templates/` and each one contains a `.devkit/` directory.

Example:

```bash
cp -R templates/laravel/.devkit projects/demo-app/
make gen
make up
```

## Local DNS / hosts

Your chosen domains must point to `127.0.0.1`.

- Small number of domains → hosts file
- Many domains → local DNS resolver (dnsmasq / Acrylic / Pi-hole)

See: `docs/hosts.md`
