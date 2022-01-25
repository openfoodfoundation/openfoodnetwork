# frozen_string_literal: true

class JsonApiSchema
  class << self
    def attributes
      {}
    end

    def required_attributes
      []
    end

    def relationships
      []
    end

    def all_attributes
      attributes.keys
    end

    def schema(options = {})
      {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: data_properties(**options)
          },
          meta: { type: :object },
          links: { type: :object }
        },
        required: [:data]
      }
    end

    def collection(options)
      {
        type: :object,
        properties: {
          data: {
            type: :array,
            items: {
              type: :object,
              properties: data_properties(**options)
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

    private

    def data_properties(require_all: false)
      required = require_all ? all_attributes : required_attributes

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
          properties: relationships.to_h do |name|
            [
              name,
              is_singular?(name) ? RelationshipSchema.schema(name) : RelationshipSchema.collection(name)
            ]
          end
        }
      }
    end

    def is_singular?(name)
      name.to_s.singularize == name.to_s
    end
  end
end
