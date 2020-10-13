### Docker

It is possible to setup the Open Food Network app easily with Docker and Docker Compose.
The objective is to spare configuration time, in order to help people testing the app and contribute to it.
It can also be used as documentation. It is not perfect but it is used in many other projects and many devs are used to it nowadays.

### Install Docker

Please check the documentation here, https://docs.docker.com/install/ to install Docker.

For Docker Compose, information are here: https://docs.docker.com/compose/install/.

Better to have at least 2GB free on your computer in order to download images and create containers for Open Food Network app.


### Use Docker with Open Food Network

Open a terminal with a shell.

Clone the repository. If you're planning on contributing code to the project (which we [LOVE](CONTRIBUTING.md)), it is a good idea to begin by forking this repo using the Fork button in the top-right corner of this screen. You should then be able to use git clone to copy your fork onto your local machine.

```sh
$ git clone https://github.com/YOUR_GITHUB_USERNAME_HERE/openfoodnetwork
```

Otherwise, if you just want to get things running, clone from the OFN main repo:

```sh
$ git clone git@github.com:openfoodfoundation/openfoodnetwork.git
```

Go at the root of the app:

```sh
$ cd openfoodnetwork
```

Download the Docker images and build the containers:

```sh
$ docker-compose build
```

Setup the database and seed it with sample data:
```sh
$ docker-compose run web bundle exec rake db:reset
$ docker-compose run web bundle exec rake db:test:prepare
$ docker-compose run web bundle exec rake ofn:sample_data
```

Finally, run the app with all the required containers:

```sh
$ docker-compose up
```

The default admin user is 'ofn@example.com' with 'ofn123' password.
Check the app in the browser at `http://localhost:3000`.

You will then get the trace of the containers in the terminal. You can stop the containers using Ctrl-C in the terminal.

You can find some useful tips and commands [here](https://github.com/openfoodfoundation/openfoodnetwork/wiki/Docker:-useful-tips-and-commands).

### Troubleshooting
If you are using Windows and having issues related to the ruby-build not finding a definition for the ruby version, you may need to follow these commands [here](https://stackoverflow.com/questions/2517190/how-do-i-force-git-to-use-lf-instead-of-crlf-under-windows/33424884#33424884) to fix your local git config related to line breaks.
