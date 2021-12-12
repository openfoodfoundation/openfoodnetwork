# frozen_string_literal: true

class RelationshipSchema
  def self.schema(resource_name = nil)
    {
      type: :object,
      properties: {
        data: {
          type: :object,
          properties: {
            id: { type: :string },
            type: { type: :string, example: resource_name }
          }
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

  def self.collection(resource_name = nil)
    {
      type: :object,
      properties: {
        data: {
          type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :string },
              type: { type: :string, example: resource_name }
            }
          }
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
