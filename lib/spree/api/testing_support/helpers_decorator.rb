require 'spree/api/testing_support/helpers'

Spree::Api::TestingSupport::Helpers.class_eval do
  def current_api_user
    @current_api_user ||= stub_model(Spree::LegacyUser, :email => "spree@example.com", :enterprises => [])
  end
end
