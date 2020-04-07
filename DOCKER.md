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

Clone the repository:

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
