FROM ruby:3.4.8-alpine3.19 AS base
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Europe/London \
    RAILS_ROOT=/usr/src/app \
    BUNDLE_PATH=/bundles \
    BUNDLE_APP_CONFIG=/bundles
RUN apk --no-cache upgrade && \
    apk add --no-cache tzdata postgresql-client imagemagick imagemagick-jpeg && \
    apk add --no-cache --virtual wkhtmltopdf

WORKDIR $RAILS_ROOT

# Development dependencies
FROM base AS development-base
RUN apk add --no-cache --virtual .build-deps \
    build-base postgresql-dev git nodejs yarn && \
    apk add --no-cache --virtual .dev-utils \
    bash curl less vim chromium-chromedriver zlib-dev openssl-dev cmake\
    readline-dev yaml-dev sqlite-dev libxml2-dev libxslt-dev libffi-dev vips-dev && \
    curl -o /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
    chmod +x /usr/local/bin/wait-for-it

# Install yarn dependencies separately for caching
FROM development-base AS yarn-dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Install Ruby gems
FROM development-base
COPY . $RAILS_ROOT
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs "$(nproc)"
COPY --from=yarn-dependencies $RAILS_ROOT/node_modules ./node_modules
