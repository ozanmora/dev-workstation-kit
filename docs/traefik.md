# Traefik Integration

This DevKit uses **Traefik as the edge proxy**:
- Traefik terminates TLS (HTTPS)
- Traefik routes project domains to the internal Nginx service
- Nginx serves each project based on `.devkit/devkit.yml`

## Domains
Default domains (change in `.env`):
- `adminer.local.test`
- `mailpit.local.test`
- `traefik.local.test` (dashboard)

Project domains: whatever you set in each project's `.devkit/devkit.yml`.

## Important: BASE_DOMAIN changes
The Traefik "projects" router is configured for `*.local.test` by default.

If you change the base domain, update the rule in `docker-compose.yml`:

```
traefik.http.routers.projects.rule=HostRegexp(`{subdomain:[a-z0-9-]+}.YOURDOMAIN`) || Host(`YOURDOMAIN`)
```

## TLS certificate
Bootstrap generates `docker/certs/devkit.crt` + `docker/certs/devkit.key` for:
- `local.test`
- `*.local.test`

For trusted HTTPS, replace with mkcert certs (see `docs/tls.md`).
