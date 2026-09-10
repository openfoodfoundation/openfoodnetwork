# frozen_string_literal: true

module UnitPriceHelper
  # The price per unit of measurement, eg. "$1.25 / kg". The spaces around the slash don't
  # break, so the price never gets separated from its unit at the end of a line.
  #
  # The unit can be a name entered by the producer, so this joins the parts rather than
  # interpolating them into an html_safe string.
  def unit_price_with_unit(variant)
    safe_join(
      [variant.display_unit_price, variant.unit_price.unit],
      "&nbsp;/&nbsp;".html_safe
    )
  end
end
