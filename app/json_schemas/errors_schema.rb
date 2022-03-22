# frozen_string_literal: true

class ErrorsSchema
  def self.schema
    {
      type: :object,
      properties: {
        errors: {
          type: :array,
          items: {
            type: :object,
            properties: {
              title: { type: :string },
              detail: { type: :string },
              source: { type: :object }
            },
            required: [:detail]
          }
        }
      },
      required: [:errors]
    }
  end
end
