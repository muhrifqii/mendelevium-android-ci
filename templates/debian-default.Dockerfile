ARG BASE_IMAGE
ARG NODE_ARG
ARG RUBY_ARG

FROM $BASE_IMAGE

LABEL org.opencontainers.image.authors="muh_rif@live.com"
LABEL org.opencontainers.image.title="Mendelevium Android CI"
LABEL org.opencontainers.image.source=https://github.com/muhrifqii/mendelevium-android-ci
LABEL org.opencontainers.image.url=https://github.com/muhrifqii/mendelevium-android-ci
LABEL org.opencontainers.image.description="Docker image for Android CI inside ubuntu nobble with Java17, Ruby, Node.js"

ENV ROOT_TOOLS=/usr/local/mendelevium
ENV NVM_DIR="$ROOT_TOOLS/nvm" RBENV_DIR="$ROOT_TOOLS/rbenv" ANDROID_SDK_ROOT="$ROOT_TOOLS/android-sdk" JAVA_HOME="$ROOT_TOOLS/java/openjdk"
ENV PATH="$JAVA_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"
ENV PATH="$RBENV_DIR/shims:$RBENV_DIR/bin:$RBENV_DIR/plugins/ruby-build/bin:$PATH"
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

ENV VERSION_TOOLS="11076708" JAVA_VERSION="jdk-17.0.11+9"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    fontconfig \
    bzip2 \
    locales \
    ca-certificates p11-kit \
    curl wget \
    binutils \
    tzdata \
    apt-transport-https \
    gpg \
    git-core \
    html2text \
    unzip \
    python3-pip \
    rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

RUN locale-gen en_US.UTF-8

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       amd64) \
         ESUM='aa7fb6bb342319d227a838af5c363bfa1b4a670c209372f9e6585bd79da6220c'; \
         BINARY_URL='https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz'; \
         ;; \
       arm64) \
         ESUM='a900acf3ae56b000afc35468a083b6d6fd695abec87a8abdb02743d5c72f6d6d'; \
         BINARY_URL='https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.11_9.tar.gz'; \
         ;; \
       armhf) \
         ESUM='9b5c375ed7ce654083c6c1137d8daadebaf8657650576115f0deafab00d0f1d7'; \
         BINARY_URL='https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_arm_linux_hotspot_17.0.11_9.tar.gz'; \
         ;; \
       ppc64el) \
         ESUM='44bdd662c3b832cfe0b808362866b8d7a700dd60e6e39716dee97211d35c230f'; \
         BINARY_URL='https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.11_9.tar.gz'; \
         ;; \
       s390x) \
         ESUM='af3f33c14ed3e2fcd85a390575029fbf92a491f60cfdc274544ac8ad6532de47'; \
         BINARY_URL='https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_s390x_linux_hotspot_17.0.11_9.tar.gz'; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    wget --progress=dot:giga -O /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p "$JAVA_HOME"; \
    tar --extract \
        --file /tmp/openjdk.tar.gz \
        --directory "$JAVA_HOME" \
        --strip-components 1 \
        --no-same-owner \
    ; \
    rm -f /tmp/openjdk.tar.gz ${JAVA_HOME}/lib/src.zip; \
    # https://github.com/docker-library/openjdk/issues/331#issuecomment-498834472
    find "$JAVA_HOME/lib" -name '*.so' -exec dirname '{}' ';' | sort -u > /etc/ld.so.conf.d/docker-openjdk.conf; \
    ldconfig; \
    # https://github.com/docker-library/openjdk/issues/212#issuecomment-420979840
    # https://openjdk.java.net/jeps/341
    java -Xshare:dump;

RUN set -eux; \
  echo "Verifying install ..."; \
  fileEncoding="$(echo 'System.out.println(System.getProperty("file.encoding"))' | jshell -s -)"; [ "$fileEncoding" = 'UTF-8' ]; rm -rf ~/.java; \
  echo "javac --version"; javac --version; \
  echo "java --version"; java --version; \
  echo "JDK installed"

ENV NODE_VERSION=$NODE_ARG
RUN mkdir -p $NVM_DIR \
  && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
  && . $NVM_DIR/nvm.sh \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default \
  && echo "NPM installed"
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
RUN npm install -g yarn \
  && echo "Yarn installed"

ENV RUBY_VERSION=$RUBY_ARG CONFIGURE_OPTS=--disable-install-doc RBENV_ROOT=$RBENV_DIR
RUN git clone https://github.com/rbenv/rbenv.git "$RBENV_DIR" \
  && git clone https://github.com/rbenv/ruby-build.git "$RBENV_DIR/plugins/ruby-build" \
  && echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh # or /etc/profile
RUN rbenv install $RUBY_VERSION && rbenv global $RUBY_VERSION
RUN gem install bundler \
  && echo "RubyGem installed"
RUN ruby -v

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
RUN echo "Android SDK installed"