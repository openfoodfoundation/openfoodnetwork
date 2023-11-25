# frozen_string_literal: true

# This soft deletes the product
class ProductDeleter
  def self.delete(product)
    product.destroy
  end
end
