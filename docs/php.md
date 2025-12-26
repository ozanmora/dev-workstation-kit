# PHP Versions

This kit includes PHP-FPM containers for:

- 7.4 (legacy, EOL)
- 8.2
- 8.4
- 8.5

Routing is controlled per-domain via `config/routes.txt`:

```
domain|project_path|type|php
ci3.local.test|projects/ci3-app|php|74
laravel.local.test|projects/laravel-app|php|84
```

## Composer
Composer is installed in every PHP container.

Example:
```bash
docker compose exec php84 composer -V
docker compose exec php84 composer install -d /var/www/projects/laravel-app
```

You can also add your own helper wrappers if you want a single command for composer.
