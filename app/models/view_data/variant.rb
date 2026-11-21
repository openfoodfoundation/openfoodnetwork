# frozen_string_literal: true

# This represent a read only Variant value object, to be used in the view.
#
# `fees` lists the enterprise fees on its price, as EnterpriseFeeCalculator::FeeAmount.
ViewData::Variant = Data.define(:id, :on_demand, :on_hand, :display_name, :name_to_display,
                                :unit_to_display, :price, :price_with_fees,
                                :display_price_with_fees, :unit_price, :display_unit_price,
                                :fees, :enterprise, :producer, :product) do
  # From a VariantPresenter, which prices the variant: with the fees of an order cycle in the
  # shop, without fees in the admin product preview.
  def self.from_presenter(presenter, on_hand:, product:)
    new(
      **presenter.variant.slice(:id, :on_demand, :display_name, :name_to_display,
                                :unit_to_display, :price, :enterprise, :producer),
      on_hand:,
      price_with_fees: presenter.price_with_fees,
      display_price_with_fees: presenter.display_price_with_fees,
      unit_price: presenter.unit_price,
      display_unit_price: presenter.display_unit_price,
      fees: presenter.fee_breakdown,
      product:
    )
  end
end
