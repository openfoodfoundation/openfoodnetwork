# Open Food Network

Connect suppliers (ie. farmers), distributors (ie. co-ops) and
consumers (ie. local food lovers) for the sale and purchase of local
produce.


## Dependencies

* Rails 3.2.x
* Ruby >= 1.9.3
* PostgreSQL database
* PhantomJS (for testing)
* See Gemfile for a list of gems required


## Get it

The source code is managed with Git (a version control system) and
hosted at GitHub.

You can view the code at:

    https://github.com/openfoodfoundation/openfoodnetwork

You can download the source with the command:

    git clone git@github.com:openfoodfoundation/openfoodnetwork


## Get it running

For those new to Rails, the following tutorial will help get you up to speed with configuring a Rails environment: http://guides.rubyonrails.org/getting_started.html .

First, check your dependencies: Ensure that you have Ruby 1.9.x installed:

    ruby --version

Install the project's gem dependencies:

    bundle install

Create the development and test databases, using the settings specified in `config/database.yml`. You can then load the schema and some seed data with the following command:

    rake db:schema:load db:seed

Load some default data for your environment

    rake openfoodnetwork:dev:load_sample_data

At long last, your dreams of spinning up a development server can be realised:

    rails server


## Testing

Tests, both unit and integration, are based on RSpec. To run the test suite, first prepare the test database:

    bundle exec rake db:test:load

Then the tests can be run with:

    bundle exec rspec spec

The site is configured to use
[Zeus](https://github.com/burke/zeus) to reduce the pre-test
startup time while Rails loads. See the Zeus github page for
usage instructions.


## Deployment

Deployment is achieved using [Heroku](http://heroku.com). For access,
speak to Andrew Spinks.


## Credits

* Andrew Spinks (http://github.com/andrewspinks)
* Rohan Mitchell (http://github.com/rohanm)
* Rob Harrington (http://github.com/oeoeaio)
* Alex Serdyuk (http://github.com/alexs333)
* David Cook (http://github.com/dacook)
* Will Marshall (http://soundcloud.com/willmarshall)


## Licence

Copyright (c) 2012 - 2013 Open Food Foundation, released under the AGPL licence.

