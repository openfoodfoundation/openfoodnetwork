# frozen_string_literal: true

# This class patches the Stripe API response to the authorize action
# It copies the authorization URL to a field that is recognized and persisted by Spree payments
module Stripe
  class AuthorizeResponsePatcher
    def initialize(response)
      @response = response
    end

    def call!
      if (url = url_for_authorization(@response)) && field_to_patch(@response).present?
        field_to_patch(@response)['redirect_auth_url'] = url
      end

      @response
    end

    private

    def url_for_authorization(response)
      return unless %w(requires_source_action requires_action).include?(response.params["status"])

      next_action = response.params["next_source_action"] || response.params["next_action"]
      return if next_action.blank?

      next_action_type = next_action["type"]
      return unless %w(authorize_with_url redirect_to_url).include?(next_action_type)

      url = URI(next_action[next_action_type]["url"])
      # Check the URL is from a stripe subdomain
      url.to_s if url.is_a?(URI::HTTPS) && url.host.match?(/\.stripe.com\Z/)
    end

    # This field is used because the Spree code recognizes and stores it
    # This data is then used in Checkout::StripeRedirect
    def field_to_patch(response)
      response.cvv_result
    end
  end
end
