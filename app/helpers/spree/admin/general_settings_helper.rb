# frozen_string_literal: true

module Spree
  module Admin
    module GeneralSettingsHelper
      def all_units
        [
          WeightsAndMeasures::UNITS['weight'].values.pluck('name'),
          WeightsAndMeasures::UNITS['volume'].values.pluck('name')
        ].flatten.uniq
      end
    end
  end
end
