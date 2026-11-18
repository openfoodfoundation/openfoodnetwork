# frozen_string_literal: true

# Read only view data for previewing a product in the admin, as the shopfront grid would show it.
# It's built like ProductsRenderer builds it for the shop, with ViewData and VariantPresenter.
#
# But there is no shop or order cycle here: a product can be sold by many shops. So all its
# variants are shown, with their own price and stock, and no enterprise fees.
class ProductPreviewRenderer
  # Prices variants without fees, as VariantPresenter's fee calculator.
  module NoFees
    def self.indexed_fee_breakdown_for(_variant)
      []
    end
  end

  def initialize(product)
    @product = product
  end

  def product_view
    ViewData::Product.from_record(product, variants: variants_view)
  end

  private

  attr_reader :product

  def variants_view
    simple_product = ViewData::SimpleProduct.new(**product.slice(*ViewData::SimpleProduct.members))

    variants.map do |variant|
      presenter = VariantPresenter.new(variant:, enterprise_fee_calculator: NoFees)

      ViewData::Variant.from_presenter(presenter, on_hand: variant.loaded_on_hand,
                                                  product: simple_product)
    end
  end

  # Sorted by id, the default order of Spree::Product#variants
  def variants
    product.variants.
      includes(:default_price, :enterprise, :stock_items, source_variants: :enterprise)
  end
end
