# frozen_string_literal: true

class CustomerSchema < JsonApiSchema
  def self.object_name
    "customer"
  end

  def self.attributes
    {
      id: { type: :integer, example: 1 },
      enterprise_id: { type: :integer, example: 2 },
      name: { type: :string, nullable: true, example: "Alice" },
      code: { type: :string, example: "BUYER1" },
      email: { type: :string, example: "alice@example.com" }
    }
  end

  def self.required_attributes
    [:enterprise_id, :email]
  end

  def self.relationships
    [:enterprise]
  end
end
