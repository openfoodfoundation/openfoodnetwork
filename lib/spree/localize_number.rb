require 'spree/localized_number'

module Spree
  module LocalizeNumber
    def localize_number(*attributes)
      LocalizedNumber.new(self, attributes).setup
    end
  end
end
