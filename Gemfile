source 'https://rubygems.org'
ruby "2.1.5"
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

gem 'i18n', '~> 0.6.11'
gem 'i18n-js', '~> 3.2.1'
gem 'rails', '~> 4.0.0'
# gem 'rails-i18n', '~> 4.0'
gem 'rails_safe_tasks', '~> 1.0'

gem "activerecord-import"
gem 'nokogiri', '~> 1.6.8.1'

gem "order_management", path: "./engines/order_management"
gem 'web', path: './engines/web'

gem 'pg', '~> 0.21'

# OFN-maintained and patched version of Spree v2.0.4. See
# https://github.com/openfoodfoundation/openfoodnetwork/wiki/Spree-2.0-upgrade
# for details.
gem 'spree_api', github: 'openfoodfoundation/spree', branch: '2-1-0-stable'
gem 'spree_backend', github: 'openfoodfoundation/spree', branch: '2-1-0-stable'
gem 'spree_core', github: 'openfoodfoundation/spree', branch: '2-1-0-stable'

gem 'spree_i18n', github: 'spree/spree_i18n', branch: '1-3-stable'
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: '2-1-stable', ref: '1c436c738d0f086b2ca0f75a977ac16bc6cb98b9'

# Our branch contains two changes
# - Pass customer email and phone number to PayPal (merged to upstream master)
# - Change type of password from string to password to hide it in the form
# gem 'spree_paypal_express', github: "openfoodfoundation/better_spree_paypal_express", branch: "2-0-stable"
gem 'stripe'

# We need at least this version to have Digicert's root certificate
# which is needed for Pin Payments (and possibly others).
gem 'activemerchant', '~> 1.78.0'

gem 'devise', '~> 2.2.5'
gem 'devise-encryptable', '0.2.0'
gem 'jwt', '~> 2.2'
gem 'oauth2', '~> 1.4.1' # Used for Stripe Connect

gem 'daemons'
gem 'delayed_job_active_record'
gem 'delayed_job_web'

# Fix bug in simple_form preventing collection_check_boxes usage within form_for block
# When merged, revert to upstream gem
# gem 'simple_form', github: 'RohanM/simple_form'

# Spree's default pagination gem (locked to the current version used by Spree)
# We use it's methods in OFN code as well, so this is a direct dependency
gem 'kaminari', '~> 0.14.1'

gem 'andand'
gem 'angularjs-rails', '1.5.5'
gem 'aws-sdk'
gem 'bugsnag'
gem 'db2fog'
gem 'haml'
gem 'rabl'
gem 'redcarpet'
#gem 'sass', "~> 3.3"
gem 'sass-rails', groups: [:default]
gem 'truncate_html'
gem 'unicorn'

# AMS is pinned to 0.8.4 because 0.9.x is a complete re-write, as is 0.10.x
# Once Rails is updated to 5.x we should bump directly to 0.10.x
gem "active_model_serializers", "0.8.4"
gem 'activerecord-session_store'
gem 'acts-as-taggable-on', '~> 3.4'
gem 'angularjs-file-upload-rails', '~> 2.4.1'
gem 'blockenspiel'
gem 'custom_error_message', github: 'jeremydurham/custom-err-msg'
gem 'dalli'
gem 'deface'
gem 'diffy'
gem 'figaro'
gem 'geocoder'
gem 'gmaps4rails'
gem 'oj'
gem 'paper_trail', '~> 5.2.3'
gem 'paperclip', '~> 3.4.1'
gem 'protected_attributes'
gem 'rack-rewrite'
gem 'rack-ssl', require: 'rack/ssl'
gem 'roadie-rails', '~> 1.1.1'
gem 'spinjs-rails'

gem 'combine_pdf'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

gem 'foreigner'
gem 'immigrant'
gem 'roo', '~> 2.7.0'
gem 'roo-xls', '~> 1.1.0'

gem 'whenever', require: false

##########################################
###### Used to be the assets group #######
gem 'compass-rails'
gem 'coffee-rails', '~> 4.0.0'
gem 'therubyracer', '=0.12.0'
gem 'uglifier', '>= 1.0.3'
# gem 'turbo-sprockets-rails3'
gem 'foundation-icons-sass-rails'
gem 'momentjs-rails'
gem 'angular-rails-templates', '~> 0.3.0'
##########################################

gem 'foundation-rails', '= 5.5.2.1'
gem 'foundation_rails_helper', github: 'willrjmarshall/foundation_rails_helper', branch: 'rails3'

gem 'jquery-migrate-rails'
gem 'jquery-rails', '3.0.4'

# gem 'ofn-qz', github: 'openfoodfoundation/ofn-qz', ref: '60da2ae4c44cbb4c8d602f59fb5fff8d0f21db3c'

group :production, :staging do
  gem 'ddtrace'
end

group :test, :development do
  # Pretty printed test output
  gem 'atomic'
  gem 'awesome_print'
  gem 'capybara', '>= 2.15.4'
  gem 'database_cleaner', '0.7.1', require: false
  gem "factory_bot_rails", '4.8.2', require: false
  gem 'fuubar', '~> 2.4.1'
  gem 'json_spec', '~> 1.1.4'
  gem 'knapsack'
  gem 'letter_opener', '>= 1.4.1'
  gem 'rspec-rails', ">= 3.5.2"
  gem 'rspec-retry'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'timecop'
  gem 'unicorn-rails'
  gem 'webdrivers', '3.8.1'
end

group :test do
  gem 'simplecov', require: false
  gem 'webmock'
  # See spec/spec_helper.rb for instructions
  # gem 'perftools.rb'
end

group :development do
  gem 'byebug', '~> 9.0.0' # 9.1 requires ruby 2.2
  gem 'debugger-linecache'
  gem 'guard'
  gem 'guard-livereload'
  gem 'guard-rails'
  gem 'guard-rspec', '~> 4.7.3'
  gem 'listen', '3.0.8' # 3.1.0 requires ruby 2.2
  gem "newrelic_rpm", "~> 3.0"
  gem 'pry-byebug', '>= 3.4.3'
  gem 'rubocop', '>= 0.49.1'
  #gem 'spring'
  #gem 'spring-commands-rspec'

  # 1.0.9 fixed openssl issues on macOS https://github.com/eventmachine/eventmachine/issues/602
  # While we don't require this gem directly, no dependents forced the upgrade to a version
  # greater than 1.0.9, so we just required the latest available version here.
  gem 'eventmachine', '>= 1.2.3'

  gem 'rack-mini-profiler', '< 1.0.0'
end
