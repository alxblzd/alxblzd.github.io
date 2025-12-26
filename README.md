# Portfolio (Chirpy)

A Jekyll site built on the [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) theme. Use the steps below to get a reliable local build and the same output CI will check.

## Prerequisites

- Ruby 3.2 (project pins 3.2.3 in [`.ruby-version`](.ruby-version))
- Bundler 2.4+
- Git

> On macOS you can install Ruby via [Homebrew](https://brew.sh/) (`brew install ruby`) or [rbenv](https://github.com/rbenv/rbenv). On Ubuntu, install `ruby-full` from apt or use [asdf](https://asdf-vm.com/).

## Quick start (local test)

1. Clone the repo and switch to the `portfolio-crisp-refresh` branch.
2. Install Bundler if it is not already available:
   ```bash
   gem install bundler
   ```
3. Install dependencies (uses `.ruby-version` automatically when a version manager is present):
   ```bash
   bundle install
   ```
4. Run the site locally with livereload:
   ```bash
   bundle exec jekyll serve --livereload
   ```
   Visit http://127.0.0.1:4000 to verify light/dark mode, homepage, and project data render correctly.

If you want a single copy/paste to smoke-test the site, run:

```bash
git clone https://github.com/alxblzd/alxblzd.github.io.git
cd alxblzd.github.io
git checkout portfolio-crisp-refresh
gem install bundler
bundle install
bundle exec jekyll serve --livereload
```

## Setup

If you prefer a manual sequence, run the following from the project root:

1. Install bundler if it is not already available:
   ```bash
   gem install bundler
   ```
2. Install dependencies:
   ```bash
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
- If your Ruby differs from `.ruby-version`, use a version manager (rbenv/asdf) to match it for consistent builds.
- When behind a corporate proxy, configure Bundler with the appropriate mirror (e.g., `bundle config set mirror.https://rubygems.org https://your-mirror.example.com`).
- If `bundle install` returns `403 Forbidden` from rubygems.org, your network is blocking access; point Bundler at an allowed mirror or retry from a network with direct HTTPS access to rubygems.
