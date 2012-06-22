# Open Food Web

Connect suppliers (ie. farmers), distributors (ie. co-ops) and
consumers (ie. local food lovers) for the sale and purchase of local
produce.


## Dependencies

* Rails 3.x
* Ruby >= 1.9.2
* PostgreSQL database
* See Gemfile for a list of gems required


## Get it

The source code is managed with Git (a version control system) and
hosted at GitHub.

You can view the code at:

  https://github.com/andrewspinks/openfoodweb

You can download the source with the command:

  git clone git@github.com:andrewspinks/openfoodweb


## Get it running

First, you will need, at the very least, Ruby 1.9.2 installed.
http://guides.rubyonrails.org/getting_started.html


## Testing

Tests, both unit and integration, are based on RSpec. To run the test suite, first prepare the test database:

  bundle exec rake db:test:load

Then the tests can be run with:

  bundle exec rspec spec

The site is configured to use [Spork] to reduce the pre-test startup
time while Rails loads. To use it, first start up a spork instance:

  bundle exec spork

When that's ready, you can run RSpec with the --drb flag:

  bundle exec rspec --drb spec


## Deployment

Deployment with heroku
Ask Andrew Spinks for access.


## Credits

* Andrew Spinks (http://github.com/andrewspinks)
* Rohan Mitchell (http://github.com/rohanm)


## Licence

TODO
