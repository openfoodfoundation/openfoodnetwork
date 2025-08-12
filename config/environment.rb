# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

ActiveRecord::Base.include_root_in_json = true
