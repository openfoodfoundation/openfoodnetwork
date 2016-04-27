class Api::Admin::TagRuleSerializer < ActiveModel::Serializer
  def serializable_hash
    rule_specific_serializer.serializable_hash
  end

  def rule_specific_serializer
    "Api::Admin::#{object.class.to_s}Serializer".constantize.new(object)
  end
end

module Api::Admin::TagRule
  class BaseSerializer < ActiveModel::Serializer
    attributes :id, :enterprise_id, :type, :preferred_customer_tags
  end

  class DiscountOrderSerializer < BaseSerializer
    has_one :calculator, serializer: Api::Admin::Calculator::FlatPercentItemTotalSerializer
  end

  class FilterShippingMethodsSerializer < BaseSerializer
    attributes :preferred_matched_shipping_methods_visibility, :shipping_method_tags

    def shipping_method_tags
      object.preferred_shipping_method_tags.split(",")
    end
  end

  class FilterPaymentMethodsSerializer < BaseSerializer
    attributes :preferred_matched_payment_methods_visibility, :payment_method_tags

    def payment_method_tags
      object.preferred_payment_method_tags.split(",")
    end
  end

  class FilterProductsSerializer < BaseSerializer
    attributes :preferred_matched_variants_visibility, :variant_tags

    def variant_tags
      object.preferred_variant_tags.split(",")
    end
  end
end
