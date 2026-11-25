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

  # Sorted like the shop lists them: by name, then by size. In Ruby, because the name to
  # display falls back to the product name.
  def variants
    product.variants.
      includes(:default_price, :enterprise, :stock_items, source_variants: :enterprise).
      sort_by { |variant| [variant.name_to_display.to_s.downcase, variant.unit_value.to_f] }
  end
end
