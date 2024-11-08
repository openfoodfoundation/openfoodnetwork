# First stage: Build stage with all dependencies and tools
FROM ubuntu:20.04 AS build

# Set timezone and install base dependencies
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y \
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

# Setup environment variables
ENV PATH /usr/local/src/rbenv/shims:/usr/local/src/rbenv/bin:/usr/local/src/nodenv/shims:/usr/local/src/nodenv/bin:$PATH
ENV RBENV_ROOT /usr/local/src/rbenv
ENV NODENV_ROOT /usr/local/src/nodenv
ENV CONFIGURE_OPTS --disable-install-doc
ENV BUNDLE_PATH /bundles
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so

# Install rbenv and Ruby
COPY .ruby-version .ruby-version.raw
RUN cat .ruby-version.raw | tr -d '\r\t ' > .ruby-version
RUN git clone --depth 1 https://github.com/rbenv/rbenv.git ${RBENV_ROOT} && \
    git clone --depth 1 https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build && \
    echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh && \
    RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install $(cat .ruby-version) && \
    rbenv global $(cat .ruby-version)

# Install PostgreSQL client and development libraries
RUN sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main' >> /etc/apt/sources.list.d/pgdg.list" && \
    curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-10 libpq-dev

# Install nodenv and Node.js with Yarn
COPY .node-version .node-version.raw
RUN cat .node-version.raw | tr -d '\r\t ' > .node-version
RUN git clone --depth 1 https://github.com/nodenv/nodenv.git ${NODENV_ROOT} && \
    git clone --depth 1 https://github.com/nodenv/node-build.git ${NODENV_ROOT}/plugins/node-build && \
    git clone --depth 1 https://github.com/pine/nodenv-yarn-install.git ${NODENV_ROOT}/plugins/nodenv-yarn-install && \
    git clone --depth 1 https://github.com/nodenv/nodenv-package-rehash.git ${NODENV_ROOT}/plugins/nodenv-package-rehash && \
    echo 'eval "$(nodenv init -)"' >> /etc/profile.d/nodenv.sh && \
    nodenv install $(cat .node-version) && \
    nodenv global $(cat .node-version)

# Install Chrome and Chromedriver
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    sh -c "echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list" && \
    apt-get update && apt-get install -y google-chrome-stable && \
    wget -q https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip && \
    unzip chromedriver_linux64.zip -d /usr/bin && \
    chmod u+x /usr/bin/chromedriver && \

# Copy application code and install dependencies
WORKDIR /usr/src/app
COPY . /usr/src/app/
RUN ./script/install-bundler && yarn install && bundle install --jobs="$(nproc)"

# Final stage: Runtime stage with minimal necessary components
FROM ubuntu:20.04 AS development

# Set timezone and copy necessary binaries and libraries
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y \
    imagemagick \
    libjemalloc-dev \
    libssl-dev \
    libpq-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy runtime-specific environment configurations
ENV PATH /usr/local/src/rbenv/shims:/usr/local/src/rbenv/bin:/usr/local/src/nodenv/shims:/usr/local/src/nodenv/bin:$PATH
ENV BUNDLE_PATH /bundles
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so

# Copy only essential files and libraries from build stage
COPY --from=build /usr/src/app /usr/src/app
COPY --from=build /usr/local/src/rbenv /usr/local/src/rbenv
COPY --from=build /usr/local/src/nodenv /usr/local/src/nodenv
COPY --from=build /etc/profile.d/rbenv.sh /etc/profile.d/rbenv.sh
COPY --from=build /etc/profile.d/nodenv.sh /etc/profile.d/nodenv.sh
COPY --from=build /usr/bin/chromedriver /usr/bin/chromedriver
COPY --from=build /usr/bin/google-chrome-stable /usr/bin/google-chrome-stable

# Set working directory
WORKDIR /usr/src/app
