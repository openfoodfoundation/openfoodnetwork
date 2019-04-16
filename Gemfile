source 'https://rubygems.org'
ruby "2.1.5"
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

gem 'rails', '~> 3.2.22'
gem 'rails-i18n', '~> 3.0.0'
gem 'i18n', '~> 0.6.11'
gem 'i18n-js', '~> 3.2.1'

# Patched version. See http://rubysec.com/advisories/CVE-2015-5312/.
gem 'nokogiri', '>= 1.6.7.1'

gem "order_management", path: "./engines/order_management"
gem 'web', path: './engines/web'

gem 'pg'

# OFN-maintained and patched version of Spree v2.0.4. See
# https://github.com/openfoodfoundation/openfoodnetwork/wiki/Spree-2.0-upgrade
# for details.
gem 'spree', github: 'openfoodfoundation/spree', branch: '2-0-4-stable'

gem 'spree_i18n', github: 'spree/spree_i18n', branch: '1-3-stable'
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: '2-0-stable'

# Our branch contains two changes
# - Pass customer email and phone number to PayPal (merged to upstream master)
# - Change type of password from string to password to hide it in the form
gem 'spree_paypal_express', github: "openfoodfoundation/better_spree_paypal_express", branch: "2-0-stable"
gem 'stripe'

# We need at least this version to have Digicert's root certificate
# which is needed for Pin Payments (and possibly others).
gem 'activemerchant', '~> 1.78'

gem 'oauth2', '~> 1.4.1' # Used for Stripe Connect
gem 'jwt', '~> 2.1'

gem 'delayed_job_active_record'
gem 'daemons'

# Fix bug in simple_form preventing collection_check_boxes usage within form_for block
# When merged, revert to upstream gem
gem 'simple_form', github: 'RohanM/simple_form'

gem 'unicorn'
gem 'angularjs-rails', '1.5.5'
gem 'bugsnag'
gem 'haml'
gem 'sass', "~> 3.3"
gem 'sass-rails', '~> 3.2.3', groups: [:default, :assets]
gem 'redcarpet'
gem 'aws-sdk'
gem 'db2fog'
gem 'andand'
gem 'truncate_html'
gem 'rabl'

# AMS is pinned to 0.8.4 because 0.9.x is a complete re-write, as is 0.10.x
# Once Rails is updated to 5.x we should bump directly to 0.10.x
gem "active_model_serializers", "0.8.4"
gem 'oj'
gem 'deface', '1.0.0'
gem 'paperclip', '~> 3.4.1'
gem 'dalli'
gem 'geocoder'
gem 'gmaps4rails'
gem 'spinjs-rails'
gem 'rack-ssl', require: 'rack/ssl'
gem 'rack-rewrite'
gem 'custom_error_message', github: 'jeremydurham/custom-err-msg'
gem 'angularjs-file-upload-rails', '~> 2.4.1'
gem 'roadie-rails', '~> 1.1.1'
gem 'figaro'
gem 'blockenspiel'
gem 'acts-as-taggable-on', '~> 3.4'
gem 'paper_trail', '~> 5.2.3'
gem 'diffy'
gem 'skylight', '< 2.0'

gem 'combine_pdf'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

gem 'foreigner'
gem 'immigrant'
gem 'roo', '~> 2.7.0'
gem 'roo-xls', '~> 1.1.0'

gem 'whenever', require: false

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'compass-rails'
  gem 'coffee-rails', '~> 3.2.1'

  gem 'therubyracer', '=0.12.0'

  gem 'uglifier', '>= 1.0.3'

  gem 'turbo-sprockets-rails3'
  gem 'foundation-icons-sass-rails'
  gem 'momentjs-rails'
  gem 'angular-rails-templates', '~> 0.3.0'
end

gem "foundation-rails"
gem 'foundation_rails_helper', github: 'willrjmarshall/foundation_rails_helper', branch: "rails3"

gem 'jquery-rails', '3.0.0'
gem 'jquery-migrate-rails'

gem 'ofn-qz', github: 'openfoodfoundation/ofn-qz', ref: '60da2ae4c44cbb4c8d602f59fb5fff8d0f21db3c'

group :test, :development do
  # Pretty printed test output
  gem 'fuubar', '~> 2.3.2'
  gem 'rspec-rails', ">= 3.5.2"
  gem 'shoulda-matchers'
  gem "factory_bot_rails", require: false
  gem 'capybara', '>= 2.15.4'
  gem 'database_cleaner', '0.7.1', require: false
  gem 'awesome_print'
  gem 'letter_opener', '>= 1.4.1'
  gem 'timecop'
  gem 'selenium-webdriver'
  gem 'chromedriver-helper'
  gem 'rspec-retry'
  gem 'json_spec', '~> 1.1.4'
  gem 'unicorn-rails'
  gem 'atomic'
  gem 'knapsack'
end

group :test do
  gem 'webmock'
  gem 'simplecov', require: false
  # See spec/spec_helper.rb for instructions
  #gem 'perftools.rb'
end

group :development do
  gem 'byebug', '~> 9.0.0' # 9.1 requires ruby 2.2
  gem "newrelic_rpm", "~> 3.0"
  gem 'pry-byebug', '>= 3.4.3'
  gem 'debugger-linecache'
  gem 'guard'
  gem 'listen', '3.0.8' # 3.1.0 requires ruby 2.2
  gem 'guard-livereload'
  gem 'guard-rails'
  gem 'guard-rspec', '~> 4.7.3'
  gem 'rubocop', '>= 0.49.1'
  gem 'spring', '1.7.2'
  gem 'spring-commands-rspec'

  # 1.0.9 fixed openssl issues on macOS https://github.com/eventmachine/eventmachine/issues/602
  # While we don't require this gem directly, no dependents forced the upgrade to a version
  # greater than 1.0.9, so we just required the latest available version here.
  gem 'eventmachine', '>= 1.2.3'

  gem 'rack-mini-profiler', '< 1.0.0'
end
