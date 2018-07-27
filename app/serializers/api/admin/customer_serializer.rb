class Api::Admin::CustomerSerializer < ActiveModel::Serializer
  attributes :id, :email, :enterprise_id, :user_id, :code, :tags, :tag_list, :name
  attributes :allow_charges, :default_card_present?

  has_one :ship_address, serializer: Api::AddressSerializer
  has_one :bill_address, serializer: Api::AddressSerializer

  def tag_list
    object.tag_list.join(",")
  end

  def name
    object.name.blank? ? object.bill_address.andand.full_name : object.name
  end

  def tags
    object.tag_list.map do |tag|
      tag_rule_map = options[:tag_rule_mapping].andand[tag]
      tag_rule_map || { text: tag, rules: nil }
    end
  end

  def default_card_present?
    return unless object.user
    object.user.default_card.present?
  end
end
