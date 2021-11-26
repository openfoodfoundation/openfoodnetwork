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
  libssl-dev

# Setup ENV variables
ENV PATH /usr/local/src/rbenv/shims:/usr/local/src/rbenv/bin:$PATH
ENV RBENV_ROOT /usr/local/src/rbenv
ENV CONFIGURE_OPTS --disable-install-doc
ENV BUNDLE_PATH /bundles
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so

WORKDIR /usr/src/app
COPY .ruby-version .

# Install Rbenv & Ruby
RUN git clone --depth 1 https://github.com/rbenv/rbenv.git ${RBENV_ROOT} && \
    git clone --depth 1 https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build && \
    echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh && \
    RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install $(cat .ruby-version) && \
    rbenv global $(cat .ruby-version) && \
    gem install bundler --version=1.17.3

# Install Postgres
RUN sh -c "echo 'deb https://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main' > /etc/apt/sources.list.d/pgdg.list" && \
    wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -yqq --no-install-recommends postgresql-client-9.5 libpq-dev

# Install NodeJs and yarn
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install --no-install-recommends -y nodejs \
    && npm install -g yarn

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
