module Api
  module Admin
    module Reports
      class VariantSerializer < ActiveModel::Serializer
        attributes :id, :options_text, :sku, :value, :unit, :weight_from_unit_value

        def value
          OpenFoodNetwork::OptionValueNamer.new(object).value
        end

        def unit
          OpenFoodNetwork::OptionValueNamer.new(object).unit
        end

        def weight_from_unit_value
          object.weight_from_unit_value || 0
        end
      end
    end
  end
end
