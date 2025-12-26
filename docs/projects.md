# Projects Workflow (separate repos)

Keep your real projects in their own GitHub/GitLab repos and clone them into `projects/`:

```bash
mkdir -p projects
cd projects
git clone git@github.com:you/laravel-app.git laravel-app
git clone git@gitlab.com:you/ci3-app.git ci3-app
```

## Connect a project to DevKit via `.devkit/`

In each project folder, create:

```
<project>/.devkit/devkit.yml
```

Example (Laravel):

```yaml
version: 1
domain: laravel.local.test
type: php
php: "84"
path: projects/laravel-app
docroot: public
```

Then regenerate Nginx config:

```bash
./bin/devkit gen
./bin/devkit up
```

## Static React apps

Point `docroot` to your build output:

```yaml
version: 1
domain: react.local.test
type: static
path: projects/react-app
docroot: dist
```

Build using the node container:

```bash
./bin/devkit yarn -C projects/react-app install
./bin/devkit yarn -C projects/react-app build
```
