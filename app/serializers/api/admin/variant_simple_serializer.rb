# frozen_string_literal: true

module Api
  module Admin
    class VariantSimpleSerializer < ActiveModel::Serializer
      attributes :id, :name, :import_date,
                 :options_text, :unit_value, :unit_description, :unit_to_display,
                 :display_as, :display_name, :name_to_display,
                 :price, :on_demand, :on_hand

      has_many :variant_overrides

      def name
        if object.full_name.present?
          "#{object.name} - #{object.full_name}"
        else
          object.name
        end
      end

      def on_hand
        return 0 if object.on_hand.nil?

        object.on_hand
      end

      def price
        object.price.nil? ? 0.to_f : object.price
      end
    end
  end
end
