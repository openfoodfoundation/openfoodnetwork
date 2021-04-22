# frozen_string_literal: true

module Api
  module Admin
    class TagRuleSerializer < ActiveModel::Serializer
      delegate :serializable_hash, to: :rule_specific_serializer

      def rule_specific_serializer
        "Api::Admin::#{object.class}Serializer".constantize.new(object)
      end
    end
  end
end

module Api
  module Admin
    module TagRule
      class BaseSerializer < ActiveModel::Serializer
        attributes :id, :enterprise_id, :type, :is_default, :preferred_customer_tags
      end

      class FilterShippingMethodsSerializer < BaseSerializer
        attributes :preferred_matched_shipping_methods_visibility, :preferred_shipping_method_tags,
                   :shipping_method_tags

        def shipping_method_tags
          object.preferred_shipping_method_tags.split(",")
        end
      end

      class FilterPaymentMethodsSerializer < BaseSerializer
        attributes :preferred_matched_payment_methods_visibility, :preferred_payment_method_tags,
                   :payment_method_tags

        def payment_method_tags
          object.preferred_payment_method_tags.split(",")
        end
      end

      class FilterProductsSerializer < BaseSerializer
        attributes :preferred_matched_variants_visibility, :preferred_variant_tags, :variant_tags

        def variant_tags
          object.preferred_variant_tags.split(",")
        end
      end

      class FilterOrderCyclesSerializer < BaseSerializer
        attributes :preferred_matched_order_cycles_visibility,
                   :preferred_exchange_tags,
                   :exchange_tags

        def exchange_tags
          object.preferred_exchange_tags.split(",")
        end
      end
    end
  end
end
