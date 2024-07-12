FROM ubuntu:24.10

LABEL org.opencontainers.image.authors="muh_rif@live.com"

ARG fastlane=true
ARG npm=true

ENV NVM_DIR="/tools/nvm" RBENV_DIR="/tools/rbenv" ANDROID_SDK_ROOT="/android-sdk"
ENV PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator"
ENV PATH="$NVM_DIR/bin:$RBENV_DIR/shims:$RBENV_DIR/bin:$RBENV_DIR/plugins/ruby-build/bin:$PATH"
ENV DEBIAN_FRONTEND=noninteractive

ENV VERSION_TOOLS="11076708"

RUN apt-get -qq update \
  && apt-get install -qqy --no-install-recommends \
    build-essential \
    bzip2 \
    curl wget \
    apt-transport-https \
    gpg

RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null
RUN echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list

RUN apt-get -qq update \
  && apt-get install -qqy --no-install-recommends \
    git-core \
    html2text \
    libc6-i386 \
    lib32stdc++6 \
    lib32ncurses6 \
    lib32z1 \
    unzip \
    locales \
    temurin-17-jdk
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

ENV CONFIGURE_OPTS=--disable-install-doc
RUN if [ "$fastlane" = "true" ]; then \
  git clone https://github.com/rbenv/rbenv.git "$RBENV_DIR"; \
  rbenv init; \
  git clone https://github.com/rbenv/ruby-build.git "$RBENV_DIR/plugins/ruby-build"; \
  rbenv install 3.2.1; \
  rbenv global 3.2.1; \
  gem install bundler; \
  fi

RUN if [ "$npm" = "true" ]; then \
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash; \
  echo 'source $NVM_DIR/nvm.sh' >> /etc/profile; \
  /bin/bash -l -c "nvm install;" \
  "nvm use;" \
  fi

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN which java && which ruby && which npm

RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_TOOLS}_latest.zip > /cmdline-tools.zip \
  && mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
  && unzip /cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
  && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
  && rm -v /cmdline-tools.zip

RUN yes | sdkmanager --licenses >/dev/null

RUN mkdir -p /root/.android \
  && touch /root/.android/repositories.cfg \
  && sdkmanager --update

ADD packages.txt /sdk
RUN sdkmanager --package_file=/sdk/packages.txt
