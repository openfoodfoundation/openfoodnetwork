# frozen_string_literal: true

Rswag::Ui.configure do |config|
  # List the Swagger endpoints that you want to be documented through the
  # swagger-ui. The first parameter is the path (absolute or relative to the UI
  # host) to the corresponding endpoint and the second is a title that will be
  # displayed in the document selector.
  # NOTE: If you're using rspec-api to expose Swagger files
  # (under swagger_root) as JSON or YAML endpoints, then the list below should
  # correspond to the relative paths for those endpoints.

  config.swagger_endpoint '/api-docs/v1/swagger.yaml', 'API V1 Docs'
  config.swagger_endpoint '/api-docs/dfc-v1.7/swagger.yaml', 'OFN DFC API Docs'

  # Add Basic Auth in case your API is private
  # config.basic_auth_enabled = true
  # config.basic_auth_credentials 'username', 'password'
end
