# frozen_string_literal: true

module Api
  module Admin
    class CustomerSerializer < ActiveModel::Serializer
      attributes :id, :email, :enterprise_id, :user_id, :code, :tags, :tag_list, :name,
                 :allow_charges, :default_card_present?, :balance, :balance_status

      has_one :ship_address, serializer: Api::AddressSerializer
      has_one :bill_address, serializer: Api::AddressSerializer

      def name
        object.name.presence || object.bill_address.andand.full_name
      end

      def tag_list
        customer_tag_list.join(",")
      end

      def balance
        Spree::Money.new(balance_value, currency: Spree::Config[:currency]).to_s
      end

      def balance_status
        if balance_value.positive?
          "credit_owed"
        elsif balance_value.negative?
          "balance_due"
        else
          ""
        end
      end

      def tags
        customer_tag_list.map do |tag|
          tag_rule_map = options[:tag_rule_mapping].andand[tag]
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

        options[:customer_tags].andand[object.id] || []
      end

      def balance_value
        @balance_value ||=
          OpenFoodNetwork::UserBalanceCalculator.new(object.email, object.enterprise).balance
      end
    end
  end
end
