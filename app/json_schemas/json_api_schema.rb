# frozen_string_literal: true

class JsonApiSchema
  class << self
    def attributes
      {}
    end

    def required_attributes
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
          meta: { type: :object }
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
          meta: { type: :object }
        },
        required: [:data]
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
        relationships: { type: :object }
      }
    end
  end
end
