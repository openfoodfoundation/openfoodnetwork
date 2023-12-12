# frozen_string_literal: true

# This soft deletes the product
class ProductDeleter
  # @param id [int] ID of the product to be deleted
  def self.delete(id)
    product = Spree::Product.find_by(id:)
    product&.destroy
  end
end
