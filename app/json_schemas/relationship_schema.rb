# frozen_string_literal: true

class RelationshipSchema
  def self.schema
    {
      type: :object,
      properties: {
        data: {
          type: [:object, :array]
        },
        links: {
          type: :object,
          properties: {
            related: { type: :string }
          }
        }
      }
    }
  end
end
