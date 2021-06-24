# frozen_string_literal: true

# Encapsulates the concept of default stock location in creation of a product or a shipping method.

class DefaultShippingCategory
  NAME = 'Default'

  def self.create!
    Spree::ShippingCategory.create!(name: NAME)
  end

  def self.find_or_create
    Spree::ShippingCategory.find_or_create_by(name: NAME)
  end
end
