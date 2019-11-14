FROM ubuntu:18.04

# Install all the requirements
RUN apt-get update && apt-get install -y curl git build-essential software-properties-common wget zlib1g-dev libssl1.0-dev libreadline-dev libyaml-dev libffi-dev libxml2-dev libxslt1-dev wait-for-it

# Setup ENV variables
ENV PATH /usr/local/src/rbenv/shims:/usr/local/src/rbenv/bin:$PATH
ENV RBENV_ROOT /usr/local/src/rbenv
ENV CONFIGURE_OPTS --disable-install-doc
ENV BUNDLE_PATH /bundles

WORKDIR /usr/src/app
COPY .ruby-version .

# Rbenv & Ruby part
RUN git clone https://github.com/rbenv/rbenv.git ${RBENV_ROOT} && \
    git clone https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build && \
    ${RBENV_ROOT}/plugins/ruby-build/install.sh && \
    echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh && \
    rbenv install $(cat .ruby-version) && \
    rbenv global $(cat .ruby-version) && \
    gem install bundler --version=1.17.2

# Postgres
RUN sh -c "echo 'deb https://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main' > /etc/apt/sources.list.d/pgdg.list" && \
    wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -yqq --no-install-recommends postgresql-client-9.5 libpq-dev

COPY . /usr/src/app/
