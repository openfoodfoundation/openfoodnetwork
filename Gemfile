# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

ruby File.read('.ruby-version').chomp

gem 'dotenv', require: 'dotenv/load' # Load ENV vars before other gems

gem 'rails'

# Active Storage
gem "active_storage_validations"
gem "aws-sdk-s3", require: false
gem "image_processing"

gem 'activemerchant', '>= 1.78.0'
gem 'angular-rails-templates', '>= 0.3.0'
gem 'ransack', '~> 4.1.0'
gem 'responders'
gem 'webpacker', '~> 5'

gem 'i18n'
gem 'i18n-js', '~> 3.9.0'
gem 'rails-i18n'
gem 'rails_safe_tasks', '~> 1.0'

gem "activerecord-import"
gem "db2fog", github: "openfoodfoundation/db2fog", branch: "rails-7"
gem "fog-aws", "~> 2.0" # db2fog does not support v3
gem "mime-types" # required by fog

gem "validates_lengths_from_database"
gem "valid_email2"

gem "catalog", path: "./engines/catalog"
gem 'dfc_provider', path: './engines/dfc_provider'
gem "order_management", path: "./engines/order_management"
gem 'web', path: './engines/web'

gem "activerecord-postgresql-adapter"
gem "arel-helpers", "~> 2.12"
gem "pg", "~> 1.2.3"

gem 'acts_as_list', '1.0.4'
gem 'cancancan', '~> 1.15.0'
gem 'digest'
gem 'ffaker'
gem 'highline', '2.0.3' # Necessary for the install generator
gem 'json'
gem 'monetize', '~> 1.11'
gem 'paranoia', '~> 2.4'
gem 'state_machines-activerecord'
gem 'stringex', '~> 2.8.5', require: false

gem 'paypal-sdk-merchant', '1.117.2'
gem 'stripe'

gem 'devise'
gem 'devise-encryptable'
gem 'devise-i18n'
gem 'devise-token_authenticatable'
gem 'jwt', '~> 2.3'
gem 'oauth2', '~> 1.4.7' # Used for Stripe Connect

gem 'datafoodconsortium-connector'
gem 'jsonapi-serializer'
gem 'pagy', '~> 5.1'

gem 'rswag-api'
gem 'rswag-ui'

gem 'omniauth_openid_connect'
gem 'omniauth-rails_csrf_protection'
gem 'openid_connect'

gem 'angularjs-rails', '1.8.0'
gem 'bugsnag'
gem 'haml'
gem 'redcarpet'

gem 'actionpack-action_caching'
# AMS 0.9.x and 0.10.x are very different from 0.8.4 and the upgrade is not straight forward
#   AMS is deprecated, we will introduce an alternative at some point
gem "active_model_serializers", "0.8.4"
gem 'activerecord-session_store'
gem 'acts-as-taggable-on'
gem 'angularjs-file-upload-rails', '~> 2.4.1'
gem 'bigdecimal', '3.0.2'
gem 'bootsnap', require: false
gem 'geocoder'
gem 'gmaps4rails'
gem 'mimemagic', '> 0.3.5'
gem 'paper_trail'
gem 'rack-rewrite'
gem 'rack-timeout'
gem 'roadie-rails'

gem 'puma'
gem 'redis'
gem 'sidekiq'
gem 'sidekiq-scheduler'

gem "stimulus_reflex"

gem "turbo_power"
gem "turbo-rails"

gem 'combine_pdf'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

gem 'immigrant'
gem 'roo' # read spreadsheets
gem 'spreadsheet_architect' # write spreadsheets

gem 'whenever', require: false

gem 'coffee-rails', '~> 5.0.0'

gem 'angular_rails_csrf'

gem 'jquery-rails', '4.4.0'
gem 'jquery-ui-rails', '~> 4.2'
gem "select2-rails", github: "openfoodfoundation/select2-rails", branch: "v349_with_thor_v1"

gem 'good_migrations'

gem 'flipper'
gem 'flipper-active_record'
gem 'flipper-ui'

gem "view_component"
gem 'view_component_reflex', '3.1.14.pre9'

# mini_portile2 is needed when installing with Vargant
# https://openfoodnetwork.slack.com/archives/CEBMTRCNS/p1668439152992899
gem 'mini_portile2', '~> 2.8'

gem "faraday"
gem "private_address_check"

gem 'newrelic_rpm'

gem 'invisible_captcha'

group :production, :staging do
  gem 'sd_notify' # For better Systemd process management. Used by Puma.
end

group :test, :development do
  gem 'bullet'
  gem 'capybara'
  gem 'cuprite'
  gem 'database_cleaner', require: false
  gem 'debug', '>= 1.0.0'
  gem "factory_bot_rails", '6.2.0', require: false
  gem 'fuubar', '~> 2.5.1'
  gem 'json_spec', '~> 1.1.4'
  gem 'knapsack_pro'
  gem 'letter_opener', '>= 1.4.1'
  gem 'rspec-rails', ">= 3.5.2"
  gem 'rspec-retry', require: false
  gem 'rspec-sql'
  gem 'rswag'
  gem 'shoulda-matchers'
  gem 'stimulus_reflex_testing', github: "podia/stimulus_reflex_testing", branch: :main
  gem 'timecop'
end

group :test do
  gem 'pdf-reader'
  gem 'rails-controller-testing'
  gem 'simplecov', require: false
  gem 'vcr', require: false
  gem 'webmock', require: false
  # See spec/spec_helper.rb for instructions
  # gem 'perftools.rb'
end

group :development do
  gem 'debugger-linecache'
  gem 'foreman'
  gem 'listen'
  gem 'pry', '~> 0.13.0'
  gem 'query_count'
  gem 'rails-erd'
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-commands-rubocop'
  gem 'web-console'

  gem 'rack-mini-profiler', '< 3.0.0'
end
