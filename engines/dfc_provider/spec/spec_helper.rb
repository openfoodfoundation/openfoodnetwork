# frozen_string_literal: true

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.before(:each) do
    reset_spree_preferences do |spree_config|
      spree_config.set_preference(:enable_dfc_api?, true)
    end
  end
end
