# frozen_string_literal: true

require Rails.root.join("spec/swagger_helper")
require_relative "spec_helper"

RSpec.configure do |config|
  # Override swagger docs to generate only this file:
  config.swagger_docs = {
    'dfc-v1.7/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'OFN DFC API',
        version: 'v0.1.7'
      },
      components: {
        securitySchemes: {
          oidc_token: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT",
            description: "OpenID Connect token from a trusted platform"
          },
          ofn_api_token: {
            type: :apiKey,
            in: :header,
            name: 'X-Api-Token',
            description: "API token of an authorized OFN user"
          },
          ofn_session: {
            type: :apiKey,
            in: :cookie,
            name: '_ofn_session',
            description: "Session cookie of a logged in OFN user"
          },
        }
      },
      security: [
        { oidc_token: [] },
        { ofn_api_token: [] },
        { ofn_session: [] },
      ],
      paths: {},
      servers: [
        { url: "/" },
      ]
    },
  }
end
