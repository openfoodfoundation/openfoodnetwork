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
