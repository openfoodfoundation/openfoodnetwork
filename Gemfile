source 'https://rubygems.org'
ruby "2.3.7"
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

gem 'i18n', '~> 0.6.11'
gem 'i18n-js', '~> 3.7.1'
gem 'rails', '~> 4.1.16'
gem 'rails-i18n', '~> 4.0'
gem 'rails_safe_tasks', '~> 1.0'

gem "activerecord-import"

gem "catalog", path: "./engines/catalog"
gem 'dfc_provider', path: './engines/dfc_provider'
gem "order_management", path: "./engines/order_management"
gem 'web', path: './engines/web'

gem 'activerecord-postgresql-adapter'
gem 'pg', '~> 0.21.0'

# OFN-maintained and patched version of Spree v2.0.4. See
# https://github.com/openfoodfoundation/openfoodnetwork/wiki/Tech-Doc:-OFN's-Spree-fork%F0%9F%8D%B4
# for details.
gem 'spree_core', github: 'openfoodfoundation/spree', branch: '2-1-0-stable'

### Dependencies brought from spree core
gem 'acts_as_list', '= 0.2.0'
gem 'awesome_nested_set', '~> 3.0.0.rc.1'
gem 'cancan', '~> 1.6.10'
gem 'ffaker', '~> 1.16'
gem 'highline', '= 1.6.18' # Necessary for the install generator
gem 'httparty', '~> 0.18' # Used to check alerts in spree_core, this is not used in OFN.
gem 'json', '>= 1.7.7'
gem 'money', '5.1.1'
gem 'paranoia', '~> 2.0'
gem 'ransack', '~> 1.8.10'
gem 'state_machine', '1.2.0'
gem 'stringex', '~> 1.5.1'

gem 'spree_i18n', github: 'spree/spree_i18n', branch: '1-3-stable'

# Our branch contains the following changes:
# - Pass customer email and phone number to PayPal (merged to upstream master)
# - Change type of password from string to password to hide it in the form
# - Skip CA cert file and use the ones provided by the OS
gem 'spree_paypal_express', github: 'openfoodfoundation/better_spree_paypal_express', branch: '2-1-0-stable'

gem 'stripe'

# We need at least this version to have Digicert's root certificate
# which is needed for Pin Payments (and possibly others).
gem 'activemerchant', '~> 1.78.0'

gem 'devise', '~> 3.5.10' # v4.0.0 needs rails 4.1
gem 'devise-encryptable'
gem 'devise-token_authenticatable', '~> 0.4.10' # v0.5.0 needs devise v4
gem 'jwt', '~> 2.2'
gem 'oauth2', '~> 1.4.4' # Used for Stripe Connect

gem 'daemons'
gem 'delayed_job_active_record'
gem 'delayed_job_web'

# Spree's default pagination gem (locked to the current version used by Spree)
# We use it's methods in OFN code as well, so this is a direct dependency
gem 'kaminari', '~> 0.14.1'

gem 'andand'
gem 'angularjs-rails', '1.5.5'
gem 'aws-sdk', '1.11.1' # temporarily locked down due to https://github.com/aws/aws-sdk-ruby/issues/273
gem 'bugsnag'
gem 'db2fog'
gem 'haml'
gem 'redcarpet'
gem 'sass'
gem 'sass-rails'
gem 'truncate_html', '0.9.2'
gem 'unicorn'

gem 'actionpack-action_caching'
# AMS 0.9.x and 0.10.x are very different from 0.8.4 and the upgrade is not straight forward
#   AMS is deprecated, we will introduce an alternative at some point
gem "active_model_serializers", "0.8.4"
gem 'activerecord-session_store'
gem 'acts-as-taggable-on', '~> 4.0'
gem 'angularjs-file-upload-rails', '~> 2.4.1'
gem 'custom_error_message', github: 'jeremydurham/custom-err-msg'
gem 'dalli'
gem 'figaro'
gem 'geocoder'
gem 'gmaps4rails'
gem 'oj'
gem 'paper_trail', '~> 7.1.3'
gem 'paperclip', '~> 3.4.1'
gem 'rack-rewrite'
gem 'rack-ssl', require: 'rack/ssl'
gem 'roadie-rails', '~> 1.3.0'

gem 'combine_pdf'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

gem 'foreigner'
gem 'immigrant'
gem 'roo', '~> 2.8.3'

gem 'whenever', require: false

gem 'test-unit', '~> 3.3'

gem 'coffee-rails', '~> 4.2.2'
gem 'compass-rails'

gem 'mini_racer', '0.2.15'

gem 'uglifier', '>= 1.0.3'

gem 'angular-rails-templates', '~> 0.3.0'
gem 'foundation-icons-sass-rails'

gem 'foundation-rails', '= 5.5.2.1'

gem 'jquery-migrate-rails'
gem 'jquery-rails', '3.1.5'
gem 'jquery-ui-rails', '~> 4.2'
gem 'select2-rails', '~> 3.4.7'

gem 'ofn-qz', github: 'openfoodfoundation/ofn-qz', branch: 'ofn-rails-4'

group :production, :staging do
  gem 'ddtrace'
  gem 'unicorn-worker-killer'
end

group :test, :development do
  # Pretty printed test output
  gem 'atomic'
  gem 'awesome_print'
  gem 'capybara', '>= 2.18.0' # 3.0 requires rack 1.6 that only works with Rails 4.2
  gem 'database_cleaner', require: false
  gem "factory_bot_rails", '4.10.0', require: false
  gem 'fuubar', '~> 2.5.0'
  gem 'json_spec', '~> 1.1.4'
  gem 'knapsack'
  gem 'letter_opener', '>= 1.4.1'
  gem 'rspec-rails', ">= 3.5.2"
  gem 'rspec-retry'
  gem 'rswag'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'timecop'
  gem 'unicorn-rails'
  gem 'webdrivers'
end

group :test do
  gem 'simplecov', require: false
  gem 'test-prof'
  gem 'webmock'
  # See spec/spec_helper.rb for instructions
  # gem 'perftools.rb'
end

group :development do
  gem 'byebug', '~> 11.0.0' # 11.1 requires ruby 2.4
  gem 'debugger-linecache'
  gem "newrelic_rpm", "~> 3.0"
  gem "pry", "~> 0.12.0" # pry 0.13 is not compatible with pry-byebug 3.7
  gem 'pry-byebug', '~> 3.7.0' # 3.8 requires ruby 2.4
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'spring'
  gem 'spring-commands-rspec'

  # 1.0.9 fixed openssl issues on macOS https://github.com/eventmachine/eventmachine/issues/602
  # While we don't require this gem directly, no dependents forced the upgrade to a version
  # greater than 1.0.9, so we just required the latest available version here.
  gem 'eventmachine', '>= 1.2.3'

  gem 'rack-mini-profiler', '< 3.0.0'
end
