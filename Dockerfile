FROM ruby:slim

WORKDIR /srv/jekyll

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libffi-dev \
    libgdbm-dev \
    libyaml-dev \
    zlib1g-dev \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY . .

RUN if [ -d assets/lib/dayjs ]; then \
    cp -n assets/lib/dayjs/locale/en.js assets/lib/dayjs/locale/en.min.js 2>/dev/null || true; \
    cp -n assets/lib/dayjs/plugin/relativeTime.js assets/lib/dayjs/plugin/relativeTime.min.js 2>/dev/null || true; \
    cp -n assets/lib/dayjs/plugin/localizedFormat.js assets/lib/dayjs/plugin/localizedFormat.min.js 2>/dev/null || true; \
  fi

RUN bundle config set path vendor/bundle \
  && bundle install --jobs 4 --retry 3

EXPOSE 4000 35729

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--livereload", "--livereload-port", "35729"]
