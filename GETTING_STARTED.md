### Getting Started

This is a general guide to setting up an Open Food Network **development environment on your local machine**. If you want to setup OFN on a server, please have a look at the [ofn-install deployment guide](https://github.com/openfoodfoundation/ofn-install/wiki).

#### Still learning Ruby on Rails?

Head to our wiki on [Learning Rails](https://github.com/openfoodfoundation/openfoodnetwork/wiki/Learning-Rails) to find some good starting points.

### Requirements

The fastest way to make it work locally is to use Docker, you only need to setup git, see the [Docker setup guide](docker/README.md).
Otherwise, for a local setup you will need:
* Ruby and bundler (check current Ruby version in [.ruby-version](https://github.com/openfoodfoundation/openfoodnetwork/blob/master/.ruby-version) file)
    - To manage versions, it's recommended to use [rbenv](https://github.com/rbenv/rbenv) or [RVM](https://rvm.io/)
* Node and yarn (check current Node version in [.node-version](https://github.com/openfoodfoundation/openfoodnetwork/blob/master/.node-version) file)
    - [nodevn](https://github.com/nodenv/nodenv) is recommended.
* PostgreSQL database
* Redis (for background jobs)
* Chrome (for testing)

The following guides will provide OS-specific step-by-step instructions to get these requirements installed:
- [Ubuntu Setup Guide][ubuntu]
- [Debian Setup Guide][debian]
- [OSX Setup Guide][osx]

For those new to Rails, the following tutorial will help get you up to speed with configuring a [Rails environment](http://guides.rubyonrails.org/getting_started.html).

### Get it

So you have set up your local environment according to the requirements listed above. If you're planning on contributing code to the project (which we [LOVE](CONTRIBUTING.md)), it is a good idea to begin by forking this repo using the `Fork` button in the top-right corner of this screen. You should then be able to use `git clone` to copy your fork onto your local machine:

    git clone git@github.com:YOUR_GITHUB_USERNAME_HERE/openfoodnetwork.git

Jump into your new local copy of the Open Food Network:

    cd openfoodnetwork

And then add an `upstream` remote that points to the main repo:

    git remote add upstream git@github.com:openfoodfoundation/openfoodnetwork.git

Fetch the latest version of `master` from `upstream` (ie. the main repo):

    git fetch upstream master

### Get it running

First, you need to create the database user the app will use by manually typing the following in your terminal:

```sh
sudo --login --user=postgres psql -c "CREATE USER ofn WITH SUPERUSER CREATEDB PASSWORD 'f00d'"
```

This will create the "ofn" user as superuser and allowing it to create databases. If this command fails, check the [troubleshooting section](#creating-the-database) for an alternative.

Next, it is _strongly recommended_ to run the setup script.
```sh
./script/setup
```
If the script succeeds you're ready to start developing. If not, take a look at the output as it should be informative enough to help you troubleshoot.

Now, your dreams of spinning up a development server can be realised:

    foreman start

Go to [http://localhost:3000](http://localhost:3000) to play around!

To login as the default user, use:

    email: ofn@example.com
    password: ofn123
    
Seee [Locale and sample data] about loading data.

### Testing

Tests, both unit and integration, are based on RSpec. To run the test suite, first prepare the test database:

    bundle exec rake db:test:prepare

Then the main application tests can be run with:

    bundle exec rspec spec

The tests of all custom engines can be run with:

    bundle exec rspec ./engines

Note: If your OS is not explicitly supported in the setup guides then not all tests may pass. However, you may still be able to develop.

Note: The time zone on your machine should match the one defined in the `.env[.*]` file.

Once [npm dependencies are installed][karma], AngularJS tests can be run with:

    ./script/karma run

If you want karma to automatically rerun the tests on file modification, use:

    ./script/karma start

### Multilingual
Do not forget to run `rake tmp:cache:clear` after locales are updated to reload I18n js translations.

### Rubocop
The project is configured to use [rubocop][rubocop] to automatically check for style and syntax errors.

You can run rubocop against your changes using:

    rubocop

### Troubleshooting

Below are fixes to potential issues that can happen during the installation process. If these don't solve the problem, or it's not listed, feel free to reach out to the [Developer Community][slack-dev] on slack. We usually respond pretty quickly.

#### Creating the database

If the `sudo -u postgres psql -c "CREATE USER ofn WITH SUPERUSER CREATEDB PASSWORD 'f00d'"` command doesn't work, you can run the following commands instead:
```
createuser --superuser --pwprompt ofn
# Enter password for new role: f00d
# Enter it again: f00d
createdb open_food_network_dev --owner=ofn
createdb open_food_network_test --owner=ofn
```
If these commands succeed, you should be able to [continue the setup process](#get-it-running).

[developer-wiki]: https://github.com/openfoodfoundation/openfoodnetwork/wiki
[osx]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Development-Environment-Setup:-OS-X
[ubuntu]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Development-Environment-Setup:-Ubuntu
[debian]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Development-Environment-Setup:-Debian
[wiki]: https://github.com/openfoodfoundation/openfoodnetwork/wiki
[rubocop]: https://rubocop.readthedocs.io/en/latest/
[karma]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Karma
[slack-dev]: https://openfoodnetwork.slack.com/messages/C2GQ45KNU
[Locale and sample data]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Locale-and-sample-data
