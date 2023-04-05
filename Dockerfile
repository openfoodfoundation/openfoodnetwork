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
  libreadline-dev \
  libyaml-dev \
  libffi-dev \
  libxml2-dev \
  libxslt1-dev \
  wait-for-it \
  imagemagick \
  unzip \
  libjemalloc-dev \
  libssl-dev \
  ca-certificates \
  gnupg

# Setup ENV variables
ENV PATH /usr/local/src/rbenv/shims:/usr/local/src/rbenv/bin:/usr/local/src/nodenv/shims:/usr/local/src/nodenv/bin:$PATH
ENV RBENV_ROOT /usr/local/src/rbenv
ENV NODENV_ROOT /usr/local/src/nodenv
ENV CONFIGURE_OPTS --disable-install-doc
ENV BUNDLE_PATH /bundles
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so

WORKDIR /usr/src/app

# trim spaces and line return from .ruby-version file
COPY .ruby-version .ruby-version.raw
RUN cat .ruby-version.raw | tr -d '\r\t ' > .ruby-version

# Install Rbenv & Ruby
RUN git clone --depth 1 https://github.com/rbenv/rbenv.git ${RBENV_ROOT} && \
    git clone --depth 1 https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build && \
    echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh && \
    RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install $(cat .ruby-version) && \
    rbenv global $(cat .ruby-version)

# Install Postgres
RUN sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main' >> /etc/apt/sources.list.d/pgdg.list" && \
    curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null && \
    apt-get update && \
    apt-get install -yqq --no-install-recommends postgresql-client-10 libpq-dev


# trim spaces and line return from .node-version file
COPY .node-version .node-version.raw
RUN cat .node-version.raw | tr -d '\r\t ' > .node-version

# Install Node and Yarn with Nodenv
RUN git clone --depth 1 https://github.com/nodenv/nodenv.git ${NODENV_ROOT} && \
    git clone --depth 1 https://github.com/nodenv/node-build.git ${NODENV_ROOT}/plugins/node-build && \
    git clone --depth 1 https://github.com/pine/nodenv-yarn-install.git ${NODENV_ROOT}/plugins/nodenv-yarn-install && \
    git clone --depth 1 https://github.com/nodenv/nodenv-package-rehash.git ${NODENV_ROOT}/plugins/nodenv-package-rehash && \
    echo 'eval "$(nodenv init -)"' >> /etc/profile.d/nodenv.sh && \
    nodenv install $(cat .node-version) && \
    nodenv global $(cat .node-version)

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

# Install Bundler
RUN ./script/install-bundler

# Install front-end dependencies
RUN yarn install

# Run bundler install in parallel with the amount of available CPUs
RUN bundle install --jobs="$(nproc)"
