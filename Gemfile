source 'http://rubygems.org'
ruby "1.9.3"

gem 'rails', '3.2.3'

gem 'pg'
gem 'spree', '1.1.1'
gem 'spree_i18n', :git => 'git://github.com/spree/spree_i18n.git'
gem 'spree_paypal_express', :git => 'git://github.com/spree/spree_paypal_express.git'
gem 'spree_last_address', :git => 'git://github.com/dancinglightning/spree-last-address.git'


# Fix bug in simple_form preventing collection_check_boxes usage within form_for block
# When merged, revert to upstream gem
gem 'simple_form', :git => 'git://github.com/RohanM/simple_form.git'

gem 'unicorn'
gem 'bugsnag'
gem 'spree_heroku', :git => 'git://github.com/joneslee85/spree-heroku.git'
gem 'haml'
gem 'aws-s3'
gem 'andand'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
end

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
  gem 'spork', '~> 1.0rc'
  gem 'pry'
  gem 'awesome_print'
end

