# frozen_string_literal: true

# Encapsulates the concept of default stock location that OFN has, as explained
# in https://github.com/openfoodfoundation/openfoodnetwork/wiki/Spree-Upgrade%3A-Stock-locations
class DefaultStockLocation
  NAME = 'default'

  def self.find_or_create
    Spree::StockLocation.find_or_create_by(name: NAME)
  end
end
