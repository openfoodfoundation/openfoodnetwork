FROM ruby:3.1.4-alpine3.19 AS base
ARG TARGETPLATFORM
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Europe/London \
    RAILS_ROOT=/usr/src/app
RUN apk --no-cache upgrade
RUN apk add --no-cache tzdata
# Only packages required to run Rails in the production environment can be added to `.essentials`.
# postgresql-dev: Required by the postgre gem
# imagemagick, imagemagick-jpeg: Required by the mini_magick gem
# wkhtmltopdf: Required by wicked_pdf and wkhtmltopdf-binary
RUN set -e && \
    apk add --no-cache --virtual .essentials \
      postgresql-client \
      imagemagick \
      imagemagick-jpeg && \
    apk add --no-cache --virtual wkhtmltopdf

WORKDIR $RAILS_ROOT

FROM base AS development-base
RUN apk add --no-cache --virtual .build-deps build-base postgresql-dev git nodejs yarn

# Adjust pre-packaged Alpine gems and software to match current version of OpenFoodNetwork
RUN gem install bundler -v '2.4.3'
RUN gem install rake -v '13.2.1' && gem uninstall rake -v '13.0.6' --executables || true

RUN <<EOF
set -e
# less: Used for 'rails console'
# vim: Used for 'rails credentials:edit'
# chromium-chromedriver: Used for feature specs
apk add --no-cache --virtual .dev-utils \
  bash \
  curl \
  less \
  vim \
  zlib-dev \
  openssl-dev \
  readline-dev \
  yaml-dev \
  sqlite-dev \
  sqlite \
  libxml2-dev \
  libxslt-dev \
  libffi-dev \
  vips-dev \
  chromium-chromedriver
apk add --no-cache bash curl \
    && curl -o /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    && chmod +x /usr/local/bin/wait-for-it
EOF

FROM development-base AS yarn-dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

FROM development-base AS development
COPY . $RAILS_ROOT
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs "$(nproc)"
COPY --from=yarn-dependencies $RAILS_ROOT/node_modules ./node_modules
