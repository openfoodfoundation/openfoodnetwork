# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

class JsonApiSchema
  module Structure
    extend self

    def schema(data_properties)
      {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: data_properties
          },
          meta: { type: :object },
          links: { type: :object }
        },
        required: [:data]
      }
    end

    def collection(data_properties)
      {
        type: :object,
        properties: {
          data: {
            type: :array,
            items: {
              type: :object,
              properties: data_properties
            }
          },
          meta: {
            type: :object,
            properties: {
              pagination: {
                type: :object,
                properties: {
                  results: { type: :integer, example: 250 },
                  pages: { type: :integer, example: 5 },
                  page: { type: :integer, example: 2 },
                  per_page: { type: :integer, example: 50 },
                }
              }
            },
            required: [:pagination]
          },
          links: {
            type: :object,
            properties: {
              self: { type: :string },
              first: { type: :string },
              prev: { type: :string, nullable: true },
              next: { type: :string, nullable: true },
              last: { type: :string }
            }
          }
        },
        required: [:data, :meta, :links]
      }
    end

    def data_properties(object_name, attributes, required, relationship_properties)
      {
        id: { type: :string, example: "1" },
        type: { type: :string, example: object_name },
        attributes: {
          type: :object,
          properties: attributes,
          required: required
        },
        relationships: {
          type: :object,
          properties: relationship_properties
        }
      }
    end
  end
end

# rubocop:enable Metrics/MethodLength
