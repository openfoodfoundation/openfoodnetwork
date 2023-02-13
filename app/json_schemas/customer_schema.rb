# frozen_string_literal: true

class CustomerSchema < JsonApiSchema
  def self.object_name
    "customer"
  end

  def self.attributes
    {
      id: { type: :integer, example: 1 },
      enterprise_id: { type: :integer, example: 2 },
      first_name: { type: :string, nullable: true, example: "Alice" },
      last_name: { type: :string, nullable: true, example: "Springs" },
      code: { type: :string, nullable: true, example: "BUYER1" },
      email: { type: :string, example: "alice@example.com" },
      allow_charges: { type: :boolean, example: false },
      tags: { type: :array, items: { type: :string }, example: ["staff", "discount"] },
      terms_and_conditions_accepted_at: {
        type: :string, format: "date-time", nullable: true,
        example: "2022-03-12T15:55:00.000+11:00",
      },
      billing_address: {
        type: :object, nullable: true,
        example: nil,
      },
      shipping_address: {
        type: :object, nullable: true,
        example: address_example,
      },
    }
  end

  def self.address_example
    {
      phone: "0404 333 222 111",
      latitude: -37.817375100000,
      longitude: 144.964803195704,
      first_name: "Alice",
      last_name: "Springs",
      street_address_1: "1 Flinders Street",
      street_address_2: "",
      postal_code: "1234",
      locality: "Melbourne",
      region: { code: "Vic", name: "Victoria" },
      country: { code: "AU", name: "Australia" },
    }
  end

  def self.required_attributes
    [:enterprise_id, :email]
  end

  def self.writable_attributes
    attributes.except(
      :id,
      :allow_charges,
      :terms_and_conditions_accepted_at,
    )
  end

  def self.relationships
    [:enterprise]
  end

  # Optional attributes included with eg: CustomerSchema.schema(extra_fields: :balance)
  def self.balance
    { balance: { type: :number, format: :double } }
  end
end
