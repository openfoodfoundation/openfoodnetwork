module Spree
  module BaseHelper
    # human readable list of variant options
    # Override: Do not show out of stock text
    def variant_options(v, options={})
      v.options_text
    end
  end
end
