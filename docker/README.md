# Docker Scripts

## What's the point?
* Setting up the Open Food Network app on your local machine is quick and easy with the aid of Docker.
* Docker provides a common virtual environment available to all developers and resolves the infamous "but it works on my machine" problem.
* Use the scripts in this directory to execute tasks in Docker. Please note that these scripts are intended to be executed from this app's root directory (/openfoodnetwork). These scripts allow you to bypass the need to keep typing "docker-compose run web".

## Installing Docker
### Requirements
* You should have at least 2 GB free on your local machine to download Docker images and create Docker containers for this app.

### Installation
#### Linux
* Visit https://docs.docker.com/engine/install/#server and select your Linux distribution to install Docker Engine.
Note: There is no need to install Docker Desktop on Linux.
* Follow the installation instructions provided. Installing from Docker repositories is recommended.
* Install Docker Compose V1. Docker Engine comes with Docker Compose V2 which is not yet supported by our Docker scripts.
```sh
$ sudo apt install docker-compose
```
* To run Docker commands as a regular user instead of as root (with sudo), follow the instructions at https://docs.docker.com/engine/install/linux-postinstall/.

#### Windows and Mac (untested)
* Docker installation instructions are at https://docs.docker.com/get-docker/.
* You may have to deselect the option to use Docker Compose V2 in Docker settings to make our scripts work.

## Getting Started
* Open a terminal with a shell.
* Clone the repository. If you're planning on contributing code to the project (which we [LOVE](CONTRIBUTING.md)), begin by forking this repo with the Fork button in the top-right corner of this screen.
* Use git clone to copy your fork onto your local machine.
```sh
$ git clone https://github.com/YOUR_GITHUB_USERNAME_HERE/openfoodnetwork
```
* Otherwise, if you just want to get things running, clone from the OFN main repo:
```sh
$ git clone git@github.com:openfoodfoundation/openfoodnetwork.git

##### Windows specific steps to be able to run the bash setup scripts.
* Install WSL ubuntu distribution by running `wsl --install Ubuntu` on Windows PowerShell or Command Prompt.
* Install Windows Terminal from Microsoft Store or website.
* Spin up Ubuntu WSL on Windows terminal and finish the basic setup. For more details see [this](https://learn.microsoft.com/en-us/windows/wsl/install).
* Open Windows Terminal settings, change the working directory of Ubuntu WSL to that of the repo. 
* Go to docker settings and enable WSL and Ubuntu. Details [here](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers).
* Spin up Ubuntu on Windows Terminal. - This will be your CLI for the project

```
* Go at the root of the app:
```sh
$ cd openfoodnetwork
```
* Download the Docker images, build the Docker containers, seed the database with sample data, AND log the screen output from these tasks:
```sh
$ docker/build
```
* Run the Rails server and its required Docker containers:
```sh
$ docker/server
```
* The default admin user is 'ofn@example.com' with the password 'ofn123'.
* View the app in the browser at `http://localhost:3000`.
* You will then get the trace of the containers in the terminal. You can stop the containers using Ctrl-C in the terminal.
* You can find some useful tips and commands [here](https://github.com/openfoodfoundation/openfoodnetwork/wiki/Docker:-useful-tips-and-commands).

### Troubleshooting
* If you are using Windows and having issues related to the ruby-build not finding a definition for the ruby version, you may need to follow these commands [here](https://stackoverflow.com/questions/2517190/how-do-i-force-git-to-use-lf-instead-of-crlf-under-windows/33424884#33424884) to fix your local git config related to line breaks.
* If you’re getting the following error:
```sh
dockerpycreds.errors.InitializationError: docker-credential-desktop not installed or not available in PATH
[8929] Failed to execute script docker-compose
```
Just change the entry in ~/.docker/config.json like this (credStore instead of credsStore), and you’re good to go:
```sh
{
  "stackOrchestrator" : "swarm",
  "experimental" : "disabled",
  "credStore" : "desktop"
}
```

### Troubleshooting for M1 Apple Silicon users

1. Current Dockerfile is not architecture-agnostic, so you get an error like
```
#0 3.023 E: Failed to fetch http://security.ubuntu.com/ubuntu/dists/bionic-security/main/binary-arm64/Packages  404  Not Found [IP: 185.125.190.36 80]
#0 3.023 E: Some index files failed to download. They have been ignored, or old ones used instead.
------
failed to solve: executor failed running [/bin/sh -c apt-get update && apt-get install -y   curl   git   build-essential   software-properties-common   wget   zlib1g-dev   libreadline-dev   libyaml-dev   libffi-dev   libxml2-dev   libxslt1-dev   wait-for-it   imagemagick   unzip   libjemalloc-dev   libssl-dev   ca-certificates   gnupg]: exit code: 100
```
To solve this, we need to hack Dockerfile a bit.

Steps to follow:
- Comment out line 7 `RUN echo "deb http://security.ubuntu.com/ubuntu bionic-security main" >> /etc/apt/sources.list`
- Comment out line 33 (`ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so`) and remove `RUBY_CONFIGURE_OPTS=--with-jemalloc` from the start of line 42

You may also need to comment out stuff related to Chromedriver and Chrome. Chrome setup may work with `[arch=amd64]` removed.

See [#8421](https://github.com/openfoodfoundation/openfoodnetwork/issues/8421) for more info

2. `stack smashing detected ***: terminated`
To fix this error on server startup, you need to bump `mini-racer` gem from `0.4.0` to `0.5.0`

Based on [spree/spree_starter #984](https://github.com/spree/spree_starter/issues/984)

## Script Summary
* docker/build: This script builds the Docker containers specified for this app, seeds the database, and logs the screen output for these operations. After you use "git clone" to download this repository, run the docker/build script to start the setup process.
* docker/server: Use this script to run this app in the Rails server. This script executes the "docker-compose up" command and logs the results. If all goes well, you will be able to view this app on your local browser at http://localhost:3000/.
* docker/test: Use this script to run the entire test suite.
* docker/qtest: Use this script to run the entire test suite in quiet mode. The deprecation warnings are removed to make the test results easier to read.
* docker/run: Use this script to run commands within the Docker container. If you want shell access, enter "docker/run bash". To execute "ls -l" within the Docker container, enter "docker/run ls -l".
* docker/seed: Use this script to seed the database. Please note that this process is not compatible with simultaneously running the Rails server or tests.
* docker/nuke: Use this script to delete all Docker images and containers. This fully resets your Docker setup and is useful for making sure that the setup procedure specified for this app is complete.
* docker/cop: This script runs RuboCop.



