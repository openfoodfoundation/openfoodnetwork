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
end
