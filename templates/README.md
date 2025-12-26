# Templates

Each template folder contains a `.devkit/` directory that you can copy into a project repo.

Example:

```bash
# From DevKit repo root
cp -R templates/laravel/.devkit projects/laravel-app/
./bin/devkit gen && ./bin/devkit up
```

Available templates:
- `templates/laravel/.devkit/`
- `templates/codeigniter-ci3/.devkit/`
- `templates/codeigniter-ci4/.devkit/`
- `templates/wordpress/.devkit/`
- `templates/plain-php/.devkit/`
- `templates/react/.devkit/`
- `templates/multi-app/.devkit/` (one config controlling multiple apps)
