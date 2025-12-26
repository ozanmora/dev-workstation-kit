# Hosts & Local Domains

Your domains in `config/routes.txt` must resolve to `127.0.0.1`.

## Simple (few projects): hosts file
Add one line per domain.

macOS/Linux: `/etc/hosts`
Windows: `C:\Windows\System32\drivers\etc\hosts`

Example:
```
127.0.0.1 laravel.local.test
127.0.0.1 wp.local.test
```

## Many projects: wildcard DNS (recommended)
Hosts files do not support wildcards. Use a local DNS resolver so you can use many domains easily:

- **dnsmasq** (macOS/Linux)
- **Acrylic DNS Proxy** (Windows)
- **Pi-hole** on your LAN

Point your chosen base domain to 127.0.0.1 (e.g. `*.local.test` → `127.0.0.1`).
