class Api::Admin::EnterpriseSerializer < ActiveModel::Serializer
  attributes :name, :id, :is_primary_producer, :is_distributor, :sells, :category, :payment_method_ids, :shipping_method_ids
  attributes :producer_profile_only, :email, :long_description, :permalink
  attributes :preferred_shopfront_message, :preferred_shopfront_closed_message, :preferred_shopfront_taxon_order, :preferred_shopfront_order_cycle_order
  attributes :preferred_product_selection_from_inventory_only
  attributes :owner, :users, :tag_groups

  has_one :owner, serializer: Api::Admin::UserSerializer
  has_many :users, serializer: Api::Admin::UserSerializer

  def tag_groups
    tag_groups = []
    object.tag_rules.each do |tag_rule|
      tag_group = find_match(tag_groups, tag_rule.preferred_customer_tags.split(",").map{ |t| { text: t } })
      tag_groups << tag_group if tag_group[:rules].empty?
      tag_group[:rules] << Api::Admin::TagRuleSerializer.new(tag_rule).serializable_hash
    end
    tag_groups
  end

  def find_match(tag_groups, tags)
    tag_groups.each do |tag_group|
      return tag_group if tag_group[:tags].length == tags.length && (tag_group[:tags] & tags) == tag_group[:tags]
    end
    return { tags: tags, rules: [] }
  end
end
