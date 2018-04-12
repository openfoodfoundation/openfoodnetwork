[![Build Status](https://travis-ci.org/openfoodfoundation/openfoodnetwork.svg?branch=master)](https://travis-ci.org/openfoodfoundation/openfoodnetwork)
[![Code Climate](https://codeclimate.com/github/openfoodfoundation/openfoodnetwork.png)](https://codeclimate.com/github/openfoodfoundation/openfoodnetwork)
[![View performance data on Skylight](https://badges.skylight.io/status/EiXQ6sSKij8y.svg)](https://oss.skylight.io/app/applications/EiXQ6sSKij8y)

# Open Food Network

The Open Food Network is an online marketplace for local food. It enables a network of independent online food stores that connect farmers and food hubs (including coops, online farmers' markets, independent food businesses etc);  with individuals and local businesses. It gives farmers and food hubs an easier and fairer way to distribute their food.

Supported by the Open Food Foundation, we are proudly open source and not-for-profit - we're trying to seriously disrupt the concentration of power in global agri-food systems, and we need as many smart people working together on this as possible.

We're part of global movement - get involved!

* Fill in this short survey to tell us who you are and what you want to do with OFN: https://docs.google.com/a/eaterprises.com.au/forms/d/1zxR5vSiU9CigJ9cEaC8-eJLgYid8CR8er7PPH9Mc-30/edit#
* Find out more and join in the conversation - http://openfoodnetwork.org


## Getting started

Below are instructions for setting up a development environment for Open Food Network. More information is in the [developer wiki](https://github.com/openfoodfoundation/openfoodnetwork/wiki).

If you're interested in provisioning a server, see [the project's Ansible playbooks](https://github.com/openfoodfoundation/ofn_deployment).


### Dependencies

* Rails 3.2.x
* Ruby 2.1.5
* PostgreSQL database
* PhantomJS (for testing)
* See Gemfile for a list of gems required


### Get it

The source code is managed with Git (a version control system) and
hosted at GitHub.

You can view the code at:

    https://github.com/openfoodfoundation/openfoodnetwork

You can download the source with the command:

    git clone https://github.com/openfoodfoundation/openfoodnetwork.git


### Get it running

For those new to Rails, the following tutorial will help get you up to speed with configuring a [Rails environment](http://guides.rubyonrails.org/getting_started.html).

When ready, run `script/setup`. If the script succeeds you're ready to start developing. If not, take a look at the output as it should be informative enough to help you troubleshoot.

If you run into any other issues getting your local environment up and running please consult [the wiki](https://github.com/openfoodfoundation/openfoodnetwork/wiki).

If still you get stuck do not hesitate to open an issue reporting the full output of the script.

Now, your dreams of spinning up a development server can be realised:
```
bundle exec rails server
```
To login as Spree default user, use:
```
email: spree@example.com
password: spree123
```
### Testing

Tests, both unit and integration, are based on RSpec. To run the test suite, first prepare the test database:

    bundle exec rake db:test:prepare

Then the tests can be run with:

    bundle exec rspec spec

The site is configured to use
[Zeus](https://github.com/burke/zeus) to reduce the pre-test
startup time while Rails loads. See the Zeus github page for
usage instructions.

Once [npm dependencies are
installed](https://github.com/openfoodfoundation/openfoodnetwork/wiki/Karma), AngularJS tests can be run with:

    ./script/karma run

If you want karma to automatically rerun the tests on file modification, use:

    ./script/karma start

### Multilingual
Do not forget to run `rake tmp:cache:clear` after locales are updated to reload I18n js translations.

## Credits

* Andrew Spinks (http://github.com/andrewspinks)
* Rohan Mitchell (http://github.com/rohanm)
* Rob Harrington (http://github.com/oeoeaio)
* Alex Serdyuk (http://github.com/alexs333)
* David Cook (http://github.com/dacook)
* Will Marshall (http://soundcloud.com/willmarshall)
* Laura Summers (https://github.com/summerscope)
* Maikel Linke (https://github.com/mkllnk)
* Lynne Davis (https://github.com/lin-d-hop)
* Paul Mackay (https://github.com/pmackay)
* Steve Pettitt (https://github.com/stveep)


## Licence

Copyright (c) 2012 - 2015 Open Food Foundation, released under the AGPL licence.
