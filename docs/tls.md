# TLS / HTTPS

Bootstrap generates a self-signed cert for `local.test` + `*.local.test`.

Browsers will warn unless you trust it.

## Recommended: mkcert
Use mkcert to generate a locally trusted wildcard certificate.

High level:
1. Install mkcert
2. `mkcert -install`
3. `mkcert "*.local.test" local.test`
4. Copy outputs to:
   - `docker/certs/devkit.crt`
   - `docker/certs/devkit.key`
5. Restart nginx: `./bin/devkit up` (or `docker compose restart nginx`)
