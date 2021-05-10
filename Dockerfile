FROM ubuntu:20.04

ENV TZ Europe/London

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN echo "deb http://security.ubuntu.com/ubuntu bionic-security main" >> /etc/apt/sources.list

# Install all the requirements
RUN apt-get update && apt-get install -y \
  curl \
  git \
  build-essential \
  software-properties-common \
  wget \
  zlib1g-dev \
  libssl1.0-dev \
  libreadline-dev \
  libyaml-dev \
  libffi-dev \
  libxml2-dev \
  libxslt1-dev \
  wait-for-it \
  imagemagick \
  unzip \
  libjemalloc-dev

# Setup ENV variables
ENV PATH /usr/local/src/rbenv/shims:/usr/local/src/rbenv/bin:$PATH
ENV RBENV_ROOT /usr/local/src/rbenv
ENV CONFIGURE_OPTS --disable-install-doc
ENV BUNDLE_PATH /bundles

WORKDIR /usr/src/app
COPY .ruby-version .

# Install Rbenv & Ruby
RUN git clone --depth 1 --branch v1.1.2 https://github.com/rbenv/rbenv.git ${RBENV_ROOT} && \
    git clone --depth 1 --branch v20200520 https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build && \
    ${RBENV_ROOT}/plugins/ruby-build/install.sh && \
    echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh && \
    RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install $(cat .ruby-version) && \
    rbenv global $(cat .ruby-version) && \
    gem install bundler --version=1.17.3

# Install Postgres
RUN sh -c "echo 'deb https://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main' > /etc/apt/sources.list.d/pgdg.list" && \
    wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -yqq --no-install-recommends postgresql-client-9.5 libpq-dev

# Install node & yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y nodejs yarn

# Install Chrome
RUN wget --quiet -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    sh -c "echo 'deb [arch=amd64]  http://dl.google.com/linux/chrome/deb/ stable main' >> /etc/apt/sources.list.d/google-chrome.list" && \
    apt-get update && \
    apt-get install -fy google-chrome-stable

# Install Chromedriver
RUN wget https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip && \
    unzip chromedriver_linux64.zip -d /usr/bin && \
    chmod u+x /usr/bin/chromedriver

# Copy code and install app dependencies
COPY . /usr/src/app/

# Install front-end dependencies
RUN yarn install

# Run bundler install in parallel with the amount of available CPUs
RUN bundle install --jobs="$(nproc)"
