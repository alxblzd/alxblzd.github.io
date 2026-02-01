# Portfolio (Chirpy)

A Jekyll site built on the [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) theme. Use the steps below to get a reliable local build and the same output CI will check.

## Prerequisites (Fedora Atomic + Toolbox)

- Toolbox installed and working.
- Git.

This repo does not pin Ruby. On Fedora Atomic, the easiest path is to install the latest Ruby inside a toolbox container.

## Quick start (local test via Podman)

Best if you want a self-contained build with no host Ruby.

Build the image from the repo root:

```bash
podman build -t portfolio-site .
```

Serve the site in a container (with livereload exposed):

```bash
podman run --rm -it -p 4000:4000 -p 35729:35729 portfolio-site
```

Then visit http://127.0.0.1:4000 to verify light/dark mode, the homepage, and project data.

## Quick start (local test via Toolbox)

Best if you want faster edit/run cycles without rebuilding images.

1. Enter your existing toolbox:
   ```bash
   toolbox enter <your-container-name>
   ```
2. Install the latest build deps + Ruby (inside the toolbox):
   ```bash
   sudo dnf upgrade -y
   sudo dnf install -y ruby ruby-devel gcc make
   ```
3. Install the latest Bundler and dependencies:
   ```bash
   gem install bundler --no-document
   bundle install
   ```
4. Run the site locally with livereload:
   ```bash
   bundle exec jekyll serve --livereload
   ```
   Visit http://127.0.0.1:4000 to verify light/dark mode, homepage, and project data render correctly.

## Setup (inside Toolbox)

From the project root inside a toolbox:

```bash
gem install bundler --no-document
bundle install
```

## Local development

Serve the site with livereload:
```bash
bundle exec jekyll serve --livereload
```

Build the site for validation:
```bash
bundle exec jekyll build
```

Both commands honor `JEKYLL_ENV=production` if you want to mirror CI locally.

## Continuous integration

The repository includes a lightweight GitHub Actions workflow (`.github/workflows/jekyll-build.yml`) that caches gems and runs `bundle exec jekyll build` to keep the site shippable.
It reads the pinned Ruby from [`.ruby-version`](.ruby-version) so CI matches local builds, and it can also be triggered manually via **Run workflow** in the Actions tab when you need a fresh check.

## Troubleshooting

- If you see `command not found: jekyll`, ensure you ran `bundle install` and then re-run the commands with `bundle exec`.
- If `toolbox` is missing in VS Code’s integrated terminal, you are likely using the Flatpak build. Use:
  ```bash
  flatpak-spawn --host toolbox enter <your-container-name>
  ```
  Or set VS Code’s terminal profile to a host shell so `toolbox` is always available.
- When behind a corporate proxy, configure Bundler with a mirror (e.g., `bundle config set mirror.https://rubygems.org https://your-mirror.example.com`).
- If `bundle install` returns `403 Forbidden` from rubygems.org, your network is blocking access; point Bundler at an allowed mirror or retry from a network with direct HTTPS access to rubygems.
