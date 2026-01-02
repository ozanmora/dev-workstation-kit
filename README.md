# Dev Workstation Kit

A powerful, containerized development environment for handling multiple projects with different stacks (PHP, Node.js, static sites) seamlessly.

Built with **Docker Compose**, **Traefik**, **Nginx**, and **dnsmasq** (optional concept).

## Features

- **Multi-Stack Support**:
  - PHP 7.4, 8.2, 8.4, 8.5
  - Node.js 22 (with npm/yarn/pnpm)
  - MariaDB, Redis, Memcached, Mailpit
- **Dynamic Routing**:
  - Automatic `*.local.test` domains.
  - Custom `BASE_DOMAIN` support via `.env` (e.g., `*.192.168.1.50.nip.io`).
  - **Auto-generated** Traefik and Nginx configurations.
- **Environment Injection**:
  - `DB_HOST`, `DB_PASSWORD`, etc., from `.env` are automatically available in all PHP containers.
- **Live Edit Support**: Proxy to local dev servers (Vite/React/Vue) for Hot Module Replacement (HMR).
- **SSL/TLS**: Self-signed via `mkcert` (optional) or Traefik default generated certs.
- **Convenience**: `bin/devkit` scripts for easy management.

## Requirements

- **Docker Desktop** (Windows/Mac/Linux)
- **Node.js** (Only for generating config, optional if using the containerized script)

## Quick Start

1.  **Bootstrap**
    ```powershell
    # Windows
    .\bin\devkit.bat bootstrap
    ```
    ```bash
    # Linux/Mac
    ./bin/devkit bootstrap
    ```
    This copies `.env.example` to `.env` and starts containers.

2.  **Add a Project**

    **PHP Project:**
    ```powershell
    cd projects/my-app
    ..\..\bin\devkit.bat init --domain app.local.test --public --php 84
    ```

    **React/Vite Project:**
    ```powershell
    cd projects/my-react
    ..\..\bin\devkit.bat init --domain react.local.test --react --dev-port 5173
    ```

3.  **Apply Changes (Generate Configs)**
    **Crucial Step:** Whenever you add a project or change `.env` domains, you must run `gen`:
    ```powershell
    .\bin\devkit.bat gen
    .\bin\devkit.bat up
    ```
    *`gen` auto-updates `docker/traefik/dynamic.yml` and `docker/nginx/conf.d/*.conf`.*

4.  **Visit**
    - https://app.local.test
    - https://traefik.local.test (Dashboard)
    - https://adminer.local.test (Database)
    - https://mailpit.local.test (Email)

## Configuration (.env)

Customize your environment in `.env`. Key variables:

- `COMPOSE_PROJECT_NAME`: Names your containers (e.g., `myproj` -> `myproj-php84`).
- `BASE_DOMAIN`: The wildcard suffix (default: `local.test`).
- `TRAEFIK_ENABLE_DASHBOARD`: Set `false` to disable the dashboard route.
- `TRAEFIK_DASHBOARD_DOMAIN`, `ADMINER_DOMAIN`, `MAILPIT_DOMAIN`: Custom domains for tools.
- `DB_*`: Database credentials (automatically passed to PHP containers).

## Multi-Device / LAN Access

1.  **Update `.env`**: `BASE_DOMAIN=192.168.1.x.nip.io`
2.  **Update Projects**: Update `domain:` in `projects/*/.devkit/devkit.yml`.
3.  **Apply**:
    ```powershell
    .\bin\devkit.bat gen
    .\bin\devkit.bat up
    ```

## Directory Structure

```
.
├── .env                # Main config
├── bin/                # CLI scripts
├── docker/             # Docker config
│   ├── nginx/conf.d/   # AUTO-GENERATED config files
│   ├── traefik/
│   │   └── dynamic.yml # AUTO-GENERATED routing rules
├── projects/           # Your Code
└── scripts/            # Generator logic (gen-nginx.mjs)
```
