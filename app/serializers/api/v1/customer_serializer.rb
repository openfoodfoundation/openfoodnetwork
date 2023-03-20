# frozen_string_literal: true

module Api
  module V1
    class CustomerSerializer < BaseSerializer
      attributes :id, :enterprise_id, :first_name, :last_name, :code, :email,
                 :allow_charges, :terms_and_conditions_accepted_at

      attribute :tags, &:tag_list

      attribute :billing_address do |object|
        address(object.billing_address)
      end

      attribute :shipping_address do |object|
        address(object.shipping_address)
      end

      attribute :balance, if: proc { |record|
        record.respond_to?(:balance_value)
      }, &:balance_value

      belongs_to :enterprise, links: {
        related: ->(object) {
          url_helpers.api_v1_enterprise_url(id: object.enterprise_id)
        }
      }

      def self.address(record)
        AddressSerializer.new(record).serializable_hash.dig(:data, :attributes)
      end
    end
  end
end
