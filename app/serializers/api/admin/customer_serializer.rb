# frozen_string_literal: true

module Api
  module Admin
    class CustomerSerializer < ActiveModel::Serializer
      attributes :id, :email, :enterprise_id, :user_id, :code, :tags, :tag_list, :first_name,
                 :last_name, :allow_charges, :default_card_present?

      has_one :ship_address, serializer: Api::AddressSerializer
      has_one :bill_address, serializer: Api::AddressSerializer

      def full_name
        object.full_name.presence || object.bill_address&.full_name
      end

      def tag_list
        customer_tag_list.join(",")
      end

      def tags
        customer_tag_list.map do |tag|
          tag_rule_map = options.dig(:tag_rule_mapping, tag)
          tag_rule_map || { text: tag, rules: nil }
        end
      end

      def default_card_present?
        return unless object.user

        object.user.default_card.present?
      end

      private

      def customer_tag_list
        return object.tag_list unless options[:customer_tags]

        options.dig(:customer_tags, object.id) || []
      end
    end
  end
end
