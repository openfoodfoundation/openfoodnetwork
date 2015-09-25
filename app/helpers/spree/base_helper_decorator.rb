module Spree
  module BaseHelper
    # human readable list of variant options
    # Override: Do not show out of stock text
    def variant_options(v, options={})
      v.unit_text
    end
  end
end
