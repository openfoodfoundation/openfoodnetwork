# frozen_string_literal: true

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include OpenFoodNetwork::ApiHelper, type: :request

  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.openapi_specs = {
    'v1.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      components: {
        schemas: {
          error_response: ErrorsSchema.schema,
          # only customer#show is with extra_fields: {name: :balance, required: true}
          customer: CustomerSchema.schema(require_all: true),
          customers_collection: CustomerSchema.collection(require_all: true, extra_fields: :balance)
        },
        securitySchemes: {
          api_key_header: {
            type: :apiKey,
            name: 'X-Api-Token',
            in: :header,
            description: "Authenticates via API key passed in specified header"
          },
          api_key_param: {
            type: :apiKey,
            name: 'token',
            in: :query,
            description: "Authenticates via API key passed in specified query param"
          },
          session: {
            type: :apiKey,
            name: '_ofn_session_id',
            in: :cookie,
            description: "Authenticates using the current user's session if logged in"
          },
        }
      },
      paths: {},
      servers: [
        { url: "/" }
      ]
    },
    'v0.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V0',
        version: 'v0'
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml

  # Take example responses from Rswag specs for API documentation.
  # https://github.com/rswag/rswag#enable-auto-generation-examples-from-responses
  config.after(:each, swagger_doc: "dfc.yaml") do |example|
    # Categories and group operations of the same API endpoint.
    example.metadata[:operation][:tags] ||= [self.class.top_level_description]

    next if response&.body.blank?

    # Replace random values from generated strings for a deterministic documentation.
    response.body.gsub!(
      %r{/rails/active_storage/[0-9A-Za-z/=-]*/([^/.]+).png},
      '/rails/active_storage/url/\1.png',
    )

    # Include response as example in the documentation.
    example.metadata[:response][:content] ||= {}
    example.metadata[:response][:content].deep_merge!(
      {
        "application/json" => {
          examples: {
            test_example: {
              value: JSON.parse(response.body, symbolize_names: true)
            }
          }
        }
      }
    )
  end
end
