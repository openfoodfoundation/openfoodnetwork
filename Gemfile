source 'https://rubygems.org'
ruby "2.1.5"

gem 'rails', '3.2.21'
gem 'rails-i18n', '~> 3.0.0'
gem 'i18n', '~> 0.6.11'
gem 'i18n-js', '~> 3.0.0'

# Patched version. See http://rubysec.com/advisories/CVE-2015-5312/.
gem 'nokogiri', '>= 1.6.7.1'

gem 'pg'
gem 'spree', github: 'openfoodfoundation/spree', branch: 'spree-upgrade-step1c'
gem 'spree_i18n', github: 'spree/spree_i18n', branch: '1-3-stable'
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: '1-3-stable'

# Our branch contains two changes
# - Pass customer email and phone number to PayPal (merged to upstream master)
# - Change type of password from string to password to hide it in the form
gem 'spree_paypal_express', :github => "openfoodfoundation/better_spree_paypal_express", :branch => "hide-password"
#gem 'spree_paypal_express', :github => "spree-contrib/better_spree_paypal_express", :branch => "1-3-stable"
gem 'stripe', '~>1.51.0'

gem 'oauth2', '~> 1.2.0' # Used for Stripe Connect
gem 'jwt', '~> 1.5'

gem 'delayed_job_active_record'
gem 'daemons'

# Fix bug in simple_form preventing collection_check_boxes usage within form_for block
# When merged, revert to upstream gem
gem 'simple_form', :github => 'RohanM/simple_form'

gem 'unicorn'
gem 'angularjs-rails', '1.5.5'
gem 'bugsnag'
gem 'newrelic_rpm'
gem 'haml'
gem 'sass', "~> 3.3"
gem 'sass-rails', '~> 3.2.3', groups: [:default, :assets]
gem 'redcarpet'
gem 'aws-sdk'
gem 'db2fog'
gem 'andand'
gem 'truncate_html'
gem 'representative_view'
gem 'rabl'
gem "active_model_serializers"
gem 'oj'
gem 'deface', :github => 'spree/deface', :ref => '1110a13'
gem 'paperclip'
gem 'dalli'
gem 'geocoder'
gem 'gmaps4rails'
gem 'spinjs-rails'
gem 'rack-ssl', :require => 'rack/ssl'
gem 'custom_error_message', :github => 'jeremydurham/custom-err-msg'
gem 'angularjs-file-upload-rails', '~> 1.1.6'
gem 'roadie-rails', '~> 1.0.3'
gem 'figaro'
gem 'blockenspiel'
gem 'acts-as-taggable-on', '~> 3.4'
gem 'paper_trail', '~> 3.0.8'
gem 'diffy'

gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

gem 'foreigner'
gem 'immigrant'
gem 'roo', '~> 2.7.0'

gem 'whenever', require: false

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'compass-rails'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'

  gem 'turbo-sprockets-rails3'
  gem 'foundation-icons-sass-rails'
  gem 'momentjs-rails'
  gem 'angular-rails-templates', '~> 0.2.0'
end

gem "foundation-rails"
gem 'foundation_rails_helper', github: 'willrjmarshall/foundation_rails_helper', branch: "rails3"

gem 'jquery-rails'
gem 'jquery-migrate-rails'
gem 'css_splitter'

gem 'ofn-qz', github: 'openfoodfoundation/ofn-qz'

group :test, :development do
  # Pretty printed test output
  gem 'turn', '~> 0.8.3', :require => false
  gem 'fuubar'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'factory_girl_rails', :require => false
  gem 'capybara'
  gem 'database_cleaner', '0.7.1', :require => false
  gem 'awesome_print'
  gem 'letter_opener'
  gem 'timecop'
  gem 'poltergeist'
  gem 'rspec-retry'
  gem 'json_spec'
  gem 'unicorn-rails'
  gem 'atomic'
  gem 'knapsack'
end

group :test do
  gem 'webmock'
  # See spec/spec_helper.rb for instructions
  #gem 'perftools.rb'
end

group :development do
  gem 'pry-byebug'
  gem 'debugger-linecache'
  gem 'guard'
  gem 'guard-livereload'
  gem 'rack-livereload'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'parallel_tests'
  gem 'rubocop', '>= 0.49.1'

  # 1.0.9 fixed openssl issues on macOS https://github.com/eventmachine/eventmachine/issues/602
  # While we don't require this gem directly, no dependents forced the upgrade to a version
  # greater than 1.0.9, so we just required the latest available version here.
  gem 'eventmachine', '>= 1.2.3'
end
