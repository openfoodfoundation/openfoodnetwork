class Api::Admin::CustomerSerializer < ActiveModel::Serializer
  attributes :id, :email, :enterprise_id, :user_id, :code, :tags, :tag_list, :name,
             :allow_charges, :default_card_present?

  has_one :ship_address, serializer: Api::AddressSerializer
  has_one :bill_address, serializer: Api::AddressSerializer

  def tag_list
    customer_tag_list.join(",")
  end

  def name
    object.name.presence || object.bill_address.andand.full_name
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
end
