FROM ruby:3.4.8-slim

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

RUN bundle config set path vendor/bundle \
  && bundle install --jobs 4 --retry 3

EXPOSE 4000 35729

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--livereload", "--livereload-port", "35729"]
