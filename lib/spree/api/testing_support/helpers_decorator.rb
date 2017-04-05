require 'spree/api/testing_support/helpers'

Spree::Api::TestingSupport::Helpers.class_eval do
  def current_api_user
    @current_api_user ||= Spree::LegacyUser.new(:email => "spree@example.com", :enterprises => [])
  end
end
