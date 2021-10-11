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
      self.attributes.keys
    end

    def schema(options = {})
      {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: self.data_properties(options)
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
              properties: self.data_properties(options)
            }
          },
          meta: { type: :object }
        },
        required: [:data]
      }
    end

    private

    def data_properties(require_all: false, relationships: nil)
      required = require_all ? self.all_attributes : self.required_attributes

      {
        id: { type: :string, example: "1" },
        type: { type: :string, example: self.object_name },
        attributes: {
          type: :object,
          properties: self.attributes,
          required: required
        },
        relationships: { type: :object }
      }
    end
  end
end
