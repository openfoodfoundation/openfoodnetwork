# frozen_string_literal: true

# This represent a read only Variant value object, to be used in the view.
ViewData::Variant = Data.define(:id, :on_demand, :on_hand, :display_name, :name_to_display,
                                :unit_to_display, :price, :display_price, :unit_price,
                                :display_unit_price, :enterprise, :product)
