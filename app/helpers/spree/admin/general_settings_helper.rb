# frozen_string_literal: true

module Spree
  module Admin
    module GeneralSettingsHelper
      def all_units
        [
          "mg", "g", "kg", "T",
          "oz", "lb",
          "mL", "cL", "dL", "L", "kL",
          "gal"
        ]
      end
    end
  end
end
