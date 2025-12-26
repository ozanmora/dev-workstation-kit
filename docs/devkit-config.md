# .devkit Configuration

DevKit discovers routes by scanning:

- `projects/**/.devkit/devkit.yml`

You can define a single app or multiple apps.

## Single app

```yaml
version: 1
domain: myapp.local.test
type: php      # php | static
php: "82"      # 74 | 82 | 84 | 85 (ignored for static)
# path is optional for single-app configs; it is inferred from the devkit.yml location
# path: projects/myapp
docroot: public
```

### WordPress
Use `docroot: .` if WordPress lives in the project root.

### CodeIgniter 3
Some CI3 apps use `docroot: .` (front controller in root). Others use `public/`.

## Multi-app (one folder, many repos/apps)

If you have one “parent” folder that contains multiple independent repos, you can put one `.devkit/devkit.yml` at the parent:

```yaml
version: 1
apps:
  - domain: api.local.test
    type: php
    php: "84"
    path: projects/big/api
    docroot: public

  - domain: admin.local.test
    type: static
    path: projects/big/admin
    docroot: dist
```

This is useful when you want **one place** to manage routes for a group of apps.


## URL path prefix
You can serve an app under a URL prefix:

```yaml
url_path: /portal
```
