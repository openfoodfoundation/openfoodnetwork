# Load the rails application
require_relative 'application'

# Initialize the rails application
Openfoodnetwork::Application.initialize!

ActiveRecord::Base.include_root_in_json = true
