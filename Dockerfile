FROM ubuntu:trusty

RUN apt-get update && apt-get install -y \
    git-core \
    curl \
    zlib1g-dev \
    build-essential \
    libssl-dev \
    libreadline-dev \
    libyaml-dev \
    libsqlite3-dev \
    sqlite3 \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    python-software-properties \
    libffi-dev

RUN git clone https://github.com/rbenv/rbenv.git /root/.rbenv && \
    git clone https://github.com/rbenv/ruby-build.git /root/.rbenv/plugins/ruby-build && \
    git clone https://github.com/nodenv/nodenv.git /root/.nodenv && \
    git clone https://github.com/nodenv/node-build.git /root/.nodenv/plugins/node-build
ENV PATH /root/.rbenv/shims:/root/.rbenv/bin:/root/.nodenv/shims:/root/.nodenv/bin:$PATH

RUN rbenv install 2.1.5
RUN rbenv global 2.1.5
RUN echo "gem: --no-document" >> ~/.gemrc
RUN gem install git-up bundler zeus

RUN nodenv install 5.12.0

RUN apt-get install -y git libpq-dev imagemagick phantomjs

RUN mkdir /app
WORKDIR /app

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install

COPY package.json /app/package.json
COPY .node-version /app/.node-version
RUN npm install

ENV TZ Australia/Melbourne
ENV TIMEZONE Australia/Melbourne

COPY . /app

EXPOSE 3000

CMD rm -f /app/tmp/pids/server.pid \
    && cp config/application.yml.example config/application.yml \
    && bundle exec rake db:version || { printf '\n\n' | bundle exec rake db:setup; } \
    && bundle exec rake db:test:prepare \
    && bundle exec rails server
