<p align="center">
</p>
<h1 align="center"><i>Mendelevium</i> Android CI</h1>
<p align="center">
  <a href="https://hub.docker.com/r/muhrifqii/mendelevium-android-ci">
    <img src="https://img.shields.io/docker/pulls/muhrifqii/mendelevium-android-ci.svg?style=flat-square">
  </a>
  <a href="https://github.com/muhrifqii/mendelevium-android-ci/releases">
    <img src="https://img.shields.io/github/v/tag/muhrifqii/mendelevium-android-ci?style=flat-square">
  </a>
  <a href="https://github.com/muhrifqii/mendelevium-android-ci/blob/master/LICENSE">
    <img src="https://img.shields.io/github/license/muhrifqii/mendelevium-android-ci?style=flat-square"/>
  </a>
</p>
<p align="center">An all-in-one build tools for android Deployment</p>

---

## Summary
- [About Image](#about-image)
- [Image Tags](#image-tags)
- [CI Example](#ci-example)

## About image

This docker image contains required tools for building Android applications, especially in CI environment
It contains:
- Base OS tools (from base Ubuntu Noble)
- OpenJDK 17 `v17.0.11`
- Python3 `v3.12`
- Ruby and Bundler (used for fastlane use-case) on `rbenv`
- Node, npm, and yarn (used for react-native or ionic use-case) on `nvm`
- Android Command Line Tools (version `11076708`)

On `min` version, it only includes the base tools for android (without ruby and node)

## Image Tags
At the moment, repository tag (`<tag>`) is based on android api version (`<android_api>`) and patch (e.g. `34.1`)

Currently tools matrix (`<tools_matrix>`) used are:
- default
- `min`
- `node20`
- `node22`

Currently available os (`<os>`) are:
- `noble`

Image Tag Format is `<android_api>-<tools_matrix>-<os>`
Default Tool Matrix Image Tag Format is `<tag>` and `latest`

## Gitlab CI Example
Using default tag
```yml
build:
  stage: build
  image: muhrifqii/mendelevium-android-ci:34.1
  script:
    - npm install
    - npm run build
  after_script:
    # copying generated build for saving it as an artifact
    - cp $CI_PROJECT_DIR/android/app/build/outputs/apk/debug/app-debug.apk my-app-debug.apk
  artifacts:
    paths:
      - my-app-debug.apk
    expire_in: 1 month
    public: false
```
```yml
deploy:
  stage: deploy
  image: muhrifqii/mendelevium-android-ci:34.1
  script:
    - bundle install
    - RUBYOPT="-rostruct" bundle exec fastlane myDeployment
```

Using image with tools matrix
```yml
build:
  stage: build
  image: muhrifqii/mendelevium-android-ci:34-node20-noble
  script:
    - npm install
    - npm run build
  after_script:
    # copying generated build for saving it as an artifact
    - cp $CI_PROJECT_DIR/android/app/build/outputs/apk/debug/app-debug.apk my-app-debug.apk
  artifacts:
    paths:
      - my-app-debug.apk
    expire_in: 1 month
    public: false
```
```yml
deploy:
  stage: deploy
  image: muhrifqii/mendelevium-android-ci:34-node20-noble
  script:
    - bundle install
    - RUBYOPT="-rostruct" bundle exec fastlane myDeployment
```
