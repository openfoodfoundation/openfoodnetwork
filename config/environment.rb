# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Openfoodnetwork::Application.initialize!

ActiveRecord::Base.include_root_in_json = true
