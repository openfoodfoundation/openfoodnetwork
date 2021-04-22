# Adjust headers to allow running Storybook in development.
# Uses iframes and doesn't play nicely with CORS checks

if Rails.env.development?
  module PermissiveCORSHeaders
    def self.before(response)
      response.headers["Access-Control-Allow-Origin"] = "*"
      response.headers["Access-Control-Allow-Methods"] = "GET"
    end
  end

  ViewComponent::Storybook::StoriesController.before_action(PermissiveCORSHeaders)
end

