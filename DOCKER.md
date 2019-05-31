### Docker

It is possible to setup the Open Food Network app easily with Docker and Docker Compose.
The objective is to spare configuration time, in order to help people testing the app and contribute to it.
It can also be use as documentation. It is not perfect but it is used in many other projects and many devs are used to it nowadays.

### Install Docker

Please check the documentation here, https://docs.docker.com/install/ to install Docker.

For Docker Compose, information are here: https://docs.docker.com/compose/install/.

Better to have at least 2GB free on your laptop in order to download images and create containers for Open Food Network app.


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

Run the app with all the required containers:

```sh
$ docker-compose up
```

Check the app in the browser at `http:://localhost:3000`.

You will then get the trace of the containers in the terminal. You can stop the containers using Ctrl-C in the terminal.


When you run it for the first time, you will need to seed it with some sample data and this is not yet automated. When your app is running, you need to do this:

Connect to the container containing the app with an interactive terminal:

```sh
$ docker exec -it openfoodnetwork_web_1 bash
```

Load the seeds from Spree:

```sh
$ bundle exec rake db:seed
```

Load thre sample data from Open Food Network:

```sh
$ bundle exec rake ofn:sample_data
```

Exit and stop the container:

```sh
$ exit
```

You can then relaunch the app, and check that you have data.


### Notes

- It was not possible to integrate the seeding part directly because we need the input of the user and Docker Compose was not allowing it. Need to fix this.

- Check the code in the `ofn:dev:setup` Rake task for more details.
