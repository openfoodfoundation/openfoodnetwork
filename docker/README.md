# Docker Scripts

## What's the point?
* Setting up the Open Food Network app on your local machine is quick and easy with the aid of Docker and Docker Compose.
* Docker provides a common virtual environment available to all developers and resolves the infamous "but it works on my machine" problem.
* Use the scripts in this directory to execute tasks in Docker.  Please note that these scripts are intended to be executed from this app's root directory.  These scripts allow you to bypass the need to keep typing "docker-compose run --rm web".

## Installing Docker
* You should have at least 2 GB free on your local machine to download Docker images and create Docker containers for this app.
* Docker installation instructions are at https://docs.docker.com/install/.
* Docker Compose installation instructions are at https://docs.docker.com/compose/install/.
* To run Docker commands as a regular user instead of as root (with sudo), follow the instructions at https://docs.docker.com/engine/install/linux-postinstall/.

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
If you are using Windows and having issues related to the ruby-build not finding a definition for the ruby version, you may need to follow these commands [here](https://stackoverflow.com/questions/2517190/how-do-i-force-git-to-use-lf-instead-of-crlf-under-windows/33424884#33424884) to fix your local git config related to line breaks

## Script Summary
* docker/build: This script builds the Docker containers specified for this app, seeds the database, and logs the screen output for these operations.  After you use "git clone" to download this repository, run the docker/build script to start the setup process.
* docker/server: Use this script to run this app in the Rails server.  This script executes the "docker-compose up" command and logs the results.  If all goes well, you will be able to view this app on your local browser at http://localhost:3000/.
* docker/test: Use this script to run the entire test suite.
* docker/run: Use this script to run commands within the Docker container.  If you want shell access, enter "docker/run bash".  To execute "ls -l" within the Docker container, enter "docker/run ls -l".
* docker/seed: Use this script to seed the database.  Please note that this process is not compatible with simultaneously running the Rails server or tests.
* docker/nuke: Use this script to delete all Docker images and containers.  This fully resets your Docker setup and is useful for making sure that the setup procedure specified for this app is complete.
* docker/cop: This script runs RuboCop.


