source 'https://rubygems.org'
ruby "1.9.3"

gem 'rails', '3.2.17'

gem 'pg'
gem 'spree', :github => 'openfoodfoundation/spree', :branch => '1-3-stable'
gem 'spree_i18n', :github => 'spree/spree_i18n'
gem 'spree_auth_devise', :github => 'spree/spree_auth_devise', :branch => '1-3-stable'
gem 'spree_paypal_express', :github => 'openfoodfoundation/spree_paypal_express', :branch => '1-3-stable'

gem 'comfortable_mexican_sofa'

# Fix bug in simple_form preventing collection_check_boxes usage within form_for block
# When merged, revert to upstream gem
gem 'simple_form', :github => 'RohanM/simple_form'

gem 'unicorn'
gem 'angularjs-rails'
gem 'bugsnag'
gem 'newrelic_rpm'
gem 'haml'
gem 'sass', "~> 3.2"
gem 'sass-rails', '~> 3.2.3', groups: [:default, :assets]
gem 'aws-sdk'
gem 'db2fog'
gem 'andand'
gem 'truncate_html'
gem 'representative_view'
gem 'rabl'
gem 'oj'
gem 'chili', :github => 'openfoodfoundation/chili'
gem 'deface', :github => 'spree/deface', :ref => '1110a13'
gem 'paperclip'
gem 'geocoder'
gem 'gmaps4rails'
gem 'spinjs-rails'
gem 'rack-ssl', :require => 'rack/ssl'

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
end
gem "foundation-rails"
gem 'foundation_rails_helper', github: 'willrjmarshall/foundation_rails_helper', branch: "rails3"

gem 'jquery-rails'



group :test, :development do
  # Pretty printed test output
  gem 'turn', '~> 0.8.3', :require => false
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'factory_girl_rails', :require => false
  gem 'faker'
  gem 'capybara'
  gem 'database_cleaner', '0.7.1', :require => false
  gem 'simplecov', :require => false
  gem 'awesome_print'
  gem 'letter_opener'
  gem 'timecop'
  gem 'poltergeist'
  gem 'json_spec'
  gem 'unicorn-rails'
end

group :test do
  gem 'webmock'
end

group :chili do
  gem 'eaterprises_feature',    path: 'lib/chili/eaterprises_feature'
  gem 'local_organics_feature', path: 'lib/chili/local_organics_feature'
end

group :development do
  gem 'pry-debugger'
  gem 'debugger-linecache'
  gem 'guard'
  gem 'guard-livereload'
  gem 'rack-livereload'
  gem 'guard-rails'
  gem 'guard-zeus'
  gem 'guard-rspec'
end
