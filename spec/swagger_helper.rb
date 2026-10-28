# frozen_string_literal: true

RSpec.configure do |config|
  # True when rswag is writing documentation, see `script/rswag`.
  # Call it while running specs. Formatters aren't set up yet when this file loads.
  generating_docs = lambda do
    defined?(Rswag::Specs::SwaggerFormatter) &&
      config.formatters.any?(Rswag::Specs::SwaggerFormatter)
  end

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
          customers_collection: CustomerSchema.collection(require_all: true,
                                                          extra_fields: :balance),
          customer_account_transaction: CustomerAccountTransactionSchema.schema(require_all: true)
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

  # The legacy v0 specs need the entry above to run. But the v0 documentation
  # is written by hand, and rswag overwrites every document listed, so we leave
  # it out when generating documentation.
  config.before(:suite) do
    config.openapi_specs.delete('v0.yaml') if generating_docs.call
  end

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml

  # Database ids end up in the documented examples. Ids keep counting up between
  # test runs because rolled back transactions don't reset id sequences. Restart
  # them so that the documentation is the same on every run.
  config.before(:each, swagger_doc: "v1.yaml") do
    next unless generating_docs.call

    connection = ActiveRecord::Base.connection
    connection.tables.each { |table| connection.reset_pk_sequence!(table) }
  end

  # Take example responses from Rswag specs for API documentation.
  # https://github.com/rswag/rswag#enable-auto-generation-examples-from-responses
  config.after(:each, swagger_doc: ->(doc) { ["dfc.yaml", "v1.yaml"].include?(doc) }) do |example|
    # Some specs test details without documenting a response.
    next unless example.metadata[:response]

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
        response.headers["Content-Type"] => {
          examples: {
            self.class.description => {
              value: JSON.parse(response.body, symbolize_names: true)
            }
          }
        }
      }
    )
  end
end
