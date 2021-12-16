# frozen_string_literal: true

module FullUrlHelper
  def url_helpers
    # This is how we can get the helpers with a usable root_url outside the controllers
    Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
    Rails.application.routes.url_helpers
  end

  def full_checkout_path
    URI.join(url_helpers.root_url, url_helpers.checkout_path).to_s
  end
end
