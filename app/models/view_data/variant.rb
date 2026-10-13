# frozen_string_literal: true

# This represent a read only Variant value object, to be used in the view.
#
# `fees` are the amounts of the enterprise fees by fee type, and `fee_names` the names of
# those fees, like `{ admin: 1.5 }` and `{ admin: "Hub admin" }`.
ViewData::Variant = Data.define(:id, :on_demand, :on_hand, :display_name, :name_to_display,
                                :unit_to_display, :price, :price_with_fees,
                                :display_price_with_fees, :unit_price, :display_unit_price,
                                :fees, :fee_names, :enterprise, :producer, :product)
