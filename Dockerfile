FROM ubuntu:18.04

RUN apt-get update

## Rbenv & Ruby part

#Install all the requirements
RUN apt-get install -y curl git build-essential \
    software-properties-common
RUN apt-get install -y zlib1g-dev libssl1.0-dev libreadline-dev \
    libyaml-dev \
    libffi-dev
# For newer rubies: libssl-dev libcurl4-openssl-dev
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y nodejs yarn

#Setup ENV variables
ENV PATH /usr/local/src/rbenv/shims:/usr/local/src/rbenv/bin:$PATH
ENV RBENV_ROOT /usr/local/src/rbenv
ENV RUBY_VERSION 2.1.5
ENV CONFIGURE_OPTS --disable-install-doc


RUN git clone https://github.com/rbenv/rbenv.git ${RBENV_ROOT} \
    && git clone https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build \
    && ${RBENV_ROOT}/plugins/ruby-build/install.sh

RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh

RUN rbenv install $RUBY_VERSION \
&&  rbenv global $RUBY_VERSION
RUN gem install bundler --version=1.17.2


# Postgres
RUN apt-get install wget
RUN sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
RUN wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN apt-get install -yqq --no-install-recommends postgresql-client-9.3 libpq-dev


# App dependencies
RUN apt-get install -yqq --no-install-recommends build-essential git-core curl zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev phantomjs

# System dependencies
RUN apt-get install -y wait-for-it


ENV BUNDLE_PATH /bundles

COPY . /usr/src/app/
COPY Gemfile* /usr/src/app/

WORKDIR /usr/src/app
