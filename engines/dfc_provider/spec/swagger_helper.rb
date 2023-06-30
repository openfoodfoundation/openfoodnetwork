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
      description: <<~HTML,
        <p>
        This API implements the Data Food Consortium (DFC) specifications.
        It serves and reads semantic data encoded in JSON-LD.
        <p>
        Unfortunately, this description does not appear in the Swagger UI. :-(
      HTML
      components: {
        securitySchemes: {
          oidc_token: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT",
            description: <<~HTML
              OpenID Connect token from a trusted platform:
              <ul>
                <li><a href="https://login.lescommuns.org/auth/" target="_blank">Les Communs</a></li>
              </ul>
            HTML
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
            name: '_ofn_session_id',
            description: <<~HTML
              Session cookie of a logged in user. It allows only read access due to CSRF protection.
            HTML
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
